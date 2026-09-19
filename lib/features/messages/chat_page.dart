
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/message.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/dv_avatar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _chatService = ChatService();
  final _auth = AuthService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();


  // We'll manage pagination carefully.

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    // If scrolled to top (which is maxScrollExtent because ListView is reversed)
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      // Fetch older messages (Implementation of explicit pagination would go here if needed)
      // For this MVP, the StreamBuilder handles the first N messages natively.
      // Full two-way pagination is complex to mix with Streams.
    }
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();

    final myUid = _auth.uid;
    // Derive the other participant's ID from the deterministic conversationId
    final parts = widget.conversationId.split('_');
    final participants = parts.length == 2 ? parts : [myUid, myUid];

    await _chatService.sendMessage(
      conversationId: widget.conversationId,
      text: text,
      senderId: myUid,
      participants: participants,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Derive other participant's short ID for the header
    final parts = widget.conversationId.split('_');
    final otherUid = parts.firstWhere((id) => id != _auth.uid, orElse: () => 'Unknown');
    final shortId = otherUid.length > 4 ? otherUid.substring(otherUid.length - 4) : otherUid;

    return Scaffold(
      backgroundColor: Dv.obsidian,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            DvAvatar(name: 'PLAYER $shortId', radius: 16),
            const SizedBox(width: Dv.s12),
            Text('PLAYER $shortId', style: Dv.title(size: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              // Stream latest 50 messages
              stream: _chatService.streamLatestMessages(widget.conversationId, limit: 50),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages: ${snapshot.error}', style: Dv.body(color: Dv.crimson)));
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true, // Newest at bottom
                  padding: const EdgeInsets.all(Dv.s16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _auth.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: Dv.s8),
                        padding: const EdgeInsets.symmetric(horizontal: Dv.s16, vertical: Dv.s12),
                        decoration: BoxDecoration(
                          color: isMe ? Dv.green.withValues(alpha: 0.1) : Dv.graphite,
                          borderRadius: BorderRadius.circular(Dv.r12).copyWith(
                            bottomRight: isMe ? Radius.zero : const Radius.circular(Dv.r12),
                            bottomLeft: !isMe ? Radius.zero : const Radius.circular(Dv.r12),
                          ),
                          border: Border.all(
                            color: isMe ? Dv.green.withValues(alpha: 0.5) : Dv.steel,
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: Dv.body(color: isMe ? Dv.green : Dv.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Chat Input
          Container(
            padding: EdgeInsets.only(
              left: Dv.s16,
              right: Dv.s16,
              top: Dv.s12,
              bottom: MediaQuery.of(context).padding.bottom + Dv.s12,
            ),
            decoration: const BoxDecoration(
              color: Dv.graphite,
              border: Border(top: BorderSide(color: Dv.steel)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: Dv.body(color: Dv.white),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Tactical message...',
                      hintStyle: Dv.body(color: Dv.slate),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Dv.green),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
