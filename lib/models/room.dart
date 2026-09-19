import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { active, closed }

class Room {
  const Room({
    required this.code,
    required this.hostId,
    required this.createdAt,
    required this.status,
  });

  final String code;
  final String hostId;
  final DateTime createdAt;
  final RoomStatus status;

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      code: doc.id,
      hostId: data['hostId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: (data['status'] as String) == 'active'
          ? RoomStatus.active
          : RoomStatus.closed,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'hostId': hostId,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status == RoomStatus.active ? 'active' : 'closed',
      };

  bool get isActive => status == RoomStatus.active;
}
