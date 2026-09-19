import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/app_exception.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatService {
  ChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns a deterministic conversation ID for two users.
  String getConversationId(String uid1, String uid2) {
    final list = [uid1, uid2]..sort();
    return '${list[0]}_${list[1]}';
  }

  /// Sends a message and updates the conversation's lastMessage fields.
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String senderId,
    required List<String> participants,
  }) async {
    try {
      final batch = _firestore.batch();

      final convoRef = _firestore.collection('conversations').doc(conversationId);
      final msgRef = convoRef.collection('messages').doc();

      final msg = Message(
        id: msgRef.id,
        senderId: senderId,
        text: text,
        type: MessageType.text,
        timestamp: DateTime.now(),
        readBy: [senderId],
        createdAt: null,
      );

      // Ensure conversation document exists and is updated
      batch.set(
        convoRef,
        {
          'participants': participants,
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Add the message
      batch.set(msgRef, msg.toFirestore());

      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreException('Failed to send message: ${e.message ?? e.code}');
    } catch (e) {
      throw FirestoreException('Unexpected error sending message: $e');
    }
  }

  /// Streams active conversations for a specific user.
  Stream<List<Conversation>> streamUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Conversation.fromFirestore(doc)).toList());
  }

  /// Streams the latest messages for a conversation (real-time).
  Stream<List<Message>> streamLatestMessages(String conversationId, {int limit = 20}) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Newest first
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  /// Fetches older messages for pagination.
  Future<List<Message>> getOlderMessages(
    String conversationId,
    DocumentSnapshot lastDocument, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(lastDocument)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    } catch (e) {
      throw FirestoreException('Failed to fetch older messages: $e');
    }
  }
}
