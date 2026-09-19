import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/constants.dart';
import '../core/errors/app_exception.dart';
import '../models/room.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection(RoomConstants.roomsCollection);

  /// Generates a unique 6-character room code and creates the room in Firestore.
  /// Returns the created [Room].
  Future<Room> createRoom({required String hostId}) async {
    try {
      final code = await _generateUniqueCode();
      final room = Room(
        code: code,
        hostId: hostId,
        createdAt: DateTime.now(),
        status: RoomStatus.active,
      );
      await _rooms.doc(code).set(room.toFirestore());
      return room;
    } on FirestoreException {
      rethrow;
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to create room: ${e.message ?? e.code}');
    } catch (e) {
      throw FirestoreException('Unexpected error creating room: $e');
    }
  }

  /// Fetches a room by code. Returns null if not found.
  Future<Room?> getRoom(String code) async {
    try {
      final doc = await _rooms.doc(code.toUpperCase()).get();
      if (!doc.exists) return null;
      return Room.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to fetch room: ${e.message ?? e.code}');
    } catch (e) {
      throw FirestoreException('Unexpected error fetching room: $e');
    }
  }

  /// Marks a room as closed in Firestore.
  Future<void> closeRoom(String code) async {
    try {
      await _rooms.doc(code).update({'status': 'closed'});
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to close room: ${e.message ?? e.code}');
    }
  }

  /// Streams active rooms.
  Stream<List<Room>> streamActiveRooms() {
    return _rooms
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList());
  }

  /// Generates a unique room code not already present in Firestore.
  Future<String> _generateUniqueCode() async {
    const maxAttempts = 10;
    for (var i = 0; i < maxAttempts; i++) {
      final code = _randomCode();
      final doc = await _rooms.doc(code).get();
      if (!doc.exists) return code;
    }
    throw const FirestoreException(
      'Could not generate a unique room code. Please try again.',
    );
  }

  String _randomCode() {
    final rng = Random.secure();
    return List.generate(
      RoomConstants.codeLength,
      (_) => RoomConstants.codeChars[rng.nextInt(RoomConstants.codeChars.length)],
    ).join();
  }
}
