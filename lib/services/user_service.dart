import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../core/errors/app_exception.dart';
import '../models/user_profile.dart';
import '../models/friendship.dart';

class UserService {
  UserService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _friendships => _firestore.collection('friendships');

  // ─── Profile ────────────────────────────────────────────────────────────────

  Future<UserProfile?> getProfile(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException('Failed to get profile: $e');
    }
  }

  Stream<UserProfile?> streamProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<void> createProfile(UserProfile profile) async {
    try {
      await _users.doc(profile.uid).set({
        ...profile.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreException('Failed to create profile: $e');
    }
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    try {
      if (updates.containsKey('username')) {
        final username = updates['username'] as String;
        updates['usernameLowercase'] = username.toLowerCase();
      }
      await _users.doc(uid).update(updates);
    } catch (e) {
      throw FirestoreException('Failed to update profile: $e');
    }
  }

  Future<void> updateStatus(String uid, UserStatus status) async {
    try {
      final statusStr = switch (status) {
        UserStatus.online => 'online',
        UserStatus.inRoom => 'inRoom',
        UserStatus.offline => 'offline',
      };
      await _users.doc(uid).update({'status': statusStr});
    } catch (e) {
      // Don't throw — status update failures shouldn't crash the app
    }
  }

  /// Upload avatar to Firebase Storage, return download URL.
  Future<String> uploadAvatar(String uid, File imageFile) async {
    try {
      final ref = _storage.ref().child('users/$uid/avatar');
      final task = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw FirestoreException('Failed to upload avatar: $e');
    }
  }

  // ─── Username Search ─────────────────────────────────────────────────────────

  /// Prefix search by usernameLowercase field.
  Future<List<UserProfile>> searchByUsername(String query) async {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    try {
      final snapshot = await _users
          .where('usernameLowercase', isGreaterThanOrEqualTo: q)
          .where('usernameLowercase', isLessThan: '${q}z')
          .limit(20)
          .get();
      return snapshot.docs.map(UserProfile.fromFirestore).toList();
    } catch (e) {
      throw FirestoreException('Failed to search users: $e');
    }
  }

  /// Check if a username is available (case-insensitive).
  Future<bool> isUsernameAvailable(String username, {String? excludeUid}) async {
    final q = username.toLowerCase().trim();
    final snapshot = await _users
        .where('usernameLowercase', isEqualTo: q)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return true;
    if (excludeUid != null && snapshot.docs.first.id == excludeUid) return true;
    return false;
  }

  // ─── Friends ─────────────────────────────────────────────────────────────────

  /// Send a friend request.
  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    try {
      final id = Friendship.buildId(fromUid, toUid);
      await _friendships.doc(id).set(
        Friendship(id: id, fromUid: fromUid, toUid: toUid, status: FriendshipStatus.pending)
            .toFirestore(),
      );
    } catch (e) {
      throw FirestoreException('Failed to send friend request: $e');
    }
  }

  /// Accept a friend request.
  Future<void> acceptFriendRequest(String uid1, String uid2) async {
    final id = Friendship.buildId(uid1, uid2);
    await _friendships.doc(id).update({'status': 'accepted'});
  }

  /// Reject or cancel a friend request / remove friend.
  Future<void> removeFriend(String uid1, String uid2) async {
    final id = Friendship.buildId(uid1, uid2);
    await _friendships.doc(id).delete();
  }

  /// Block a user.
  Future<void> blockUser(String fromUid, String toUid) async {
    final id = Friendship.buildId(fromUid, toUid);
    await _friendships.doc(id).set({
      'fromUid': fromUid,
      'toUid': toUid,
      'status': 'blocked',
      'participants': [fromUid, toUid],
    });
  }

  /// Stream all friendships for a user.
  Stream<List<Friendship>> streamFriendships(String uid) {
    return _friendships
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map(Friendship.fromFirestore).toList());
  }

  /// Get the friendship status between two users.
  Future<Friendship?> getFriendship(String uid1, String uid2) async {
    final id = Friendship.buildId(uid1, uid2);
    final doc = await _friendships.doc(id).get();
    if (!doc.exists) return null;
    return Friendship.fromFirestore(doc);
  }

  /// Stream profiles of all accepted friends.
  Stream<List<UserProfile>> streamFriends(String uid) {
    return streamFriendships(uid).asyncMap((friendships) async {
      final accepted = friendships.where((f) => f.status == FriendshipStatus.accepted);
      final friendUids = accepted.map((f) => f.fromUid == uid ? f.toUid : f.fromUid).toList();
      if (friendUids.isEmpty) return <UserProfile>[];
      final profiles = await Future.wait(
        friendUids.map((id) => getProfile(id)),
      );
      return profiles.whereType<UserProfile>().toList();
    });
  }
}
