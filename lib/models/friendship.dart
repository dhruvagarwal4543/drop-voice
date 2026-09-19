import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipStatus { pending, accepted, blocked }

class Friendship {
  const Friendship({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String fromUid;
  final String toUid;
  final FriendshipStatus status;
  final DateTime? createdAt;

  factory Friendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Friendship(
      id: doc.id,
      fromUid: data['fromUid'] as String,
      toUid: data['toUid'] as String,
      status: _statusFromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fromUid': fromUid,
        'toUid': toUid,
        'status': _statusToString(status),
        'createdAt': FieldValue.serverTimestamp(),
        // Store both UIDs for efficient querying
        'participants': [fromUid, toUid],
      };

  static FriendshipStatus _statusFromString(String? s) {
    switch (s) {
      case 'accepted': return FriendshipStatus.accepted;
      case 'blocked': return FriendshipStatus.blocked;
      default: return FriendshipStatus.pending;
    }
  }

  static String _statusToString(FriendshipStatus s) {
    switch (s) {
      case FriendshipStatus.accepted: return 'accepted';
      case FriendshipStatus.blocked: return 'blocked';
      case FriendshipStatus.pending: return 'pending';
    }
  }

  /// Deterministic friendship ID so we never create duplicates
  static String buildId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
