import 'package:cloud_firestore/cloud_firestore.dart';

enum UserStatus { online, offline, inRoom }

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.usernameLowercase,
    this.avatarUrl,
    this.bio,
    this.gamingId,
    this.favouriteGame,
    this.status = UserStatus.offline,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String username;
  final String usernameLowercase;
  final String? avatarUrl;
  final String? bio;
  final String? gamingId;
  final String? favouriteGame;
  final UserStatus status;
  final DateTime? createdAt;

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Player',
      username: data['username'] as String? ?? doc.id.substring(0, 8),
      usernameLowercase: data['usernameLowercase'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      gamingId: data['gamingId'] as String?,
      favouriteGame: data['favouriteGame'] as String?,
      status: _statusFromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'username': username,
        'usernameLowercase': usernameLowercase,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (bio != null) 'bio': bio,
        if (gamingId != null) 'gamingId': gamingId,
        if (favouriteGame != null) 'favouriteGame': favouriteGame,
        'status': _statusToString(status),
        if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      };

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? gamingId,
    String? favouriteGame,
    UserStatus? status,
  }) {
    final newUsername = username ?? this.username;
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      username: newUsername,
      usernameLowercase: newUsername.toLowerCase(),
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      gamingId: gamingId ?? this.gamingId,
      favouriteGame: favouriteGame ?? this.favouriteGame,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  static UserStatus _statusFromString(String? s) {
    switch (s) {
      case 'online': return UserStatus.online;
      case 'inRoom': return UserStatus.inRoom;
      default: return UserStatus.offline;
    }
  }

  static String _statusToString(UserStatus s) {
    switch (s) {
      case UserStatus.online: return 'online';
      case UserStatus.inRoom: return 'inRoom';
      case UserStatus.offline: return 'offline';
    }
  }
}
