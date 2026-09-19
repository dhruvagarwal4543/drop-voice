import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
  });

  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'participants': participants,
    };
    if (lastMessage != null) map['lastMessage'] = lastMessage;
    if (lastMessageTime != null) {
      map['lastMessageTime'] = Timestamp.fromDate(lastMessageTime!);
    }
    return map;
  }
  
  /// Helper to get the other participant's ID in a 1-on-1 chat
  String? getOtherParticipantId(String myUid) {
    return participants.where((id) => id != myUid).firstOrNull;
  }
}
