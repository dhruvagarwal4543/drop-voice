import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, system }

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.readBy,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;
  final MessageType type;
  final DateTime timestamp;
  final List<String> readBy;
  final DateTime? createdAt; // Can be null if using server timestamp pending

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    MessageType parseType(String typeStr) {
      switch (typeStr) {
        case 'text': return MessageType.text;
        case 'image': return MessageType.image;
        case 'system': return MessageType.system;
        default: return MessageType.text;
      }
    }

    return Message(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      type: parseType(data['type'] as String? ?? 'text'),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
