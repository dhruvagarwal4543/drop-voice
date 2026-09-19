import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../models/conversation.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../widgets/dv_logo.dart';
import '../../widgets/dv_avatar.dart';
import '../../widgets/dv_text_field.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/tactical_card.dart';
import '../../widgets/telemetry_label.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _chatService = ChatService();
  final _auth = AuthService();
  final _userService = UserService();

  void _showNewChatDialog() {
    final ctrl = TextEditingController();
    List<UserProfile> results = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          return Container(
            decoration: const BoxDecoration(
              color: Dv.graphite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: Dv.s24, right: Dv.s24, top: Dv.s24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + Dv.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Dv.steel, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: Dv.s20),
                Text('NEW SECURE COMM', style: Dv.headline(size: 18)),
                const SizedBox(height: Dv.s8),
                Text('Search by username', style: Dv.body(size: 13, color: Dv.ash)),
                const SizedBox(height: Dv.s16),
                DvTextField(
                  controller: ctrl,
                  hintText: 'Search username...',
                  onChanged: (q) async {
                    if (q.trim().length < 2) {
                      setInner(() => results = []);
                      return;
                    }
                    setInner(() => isSearching = true);
                    final res = await _userService.searchByUsername(q);
                    setInner(() {
                      results = res.where((u) => u.uid != _auth.uid).toList();
                      isSearching = false;
                    });
                  },
                ),
                const SizedBox(height: Dv.s12),
                if (isSearching)
                  const Padding(padding: EdgeInsets.all(Dv.s16), child: CircularProgressIndicator(color: Dv.green, strokeWidth: 2))
                else
                  SizedBox(
                    height: 250,
                    child: results.isEmpty
                        ? Center(child: Text(ctrl.text.length >= 2 ? 'No users found.' : 'Type to search...', style: Dv.body(color: Dv.ash)))
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (_, i) {
                              final u = results[i];
                              return TacticalCard(
                                margin: const EdgeInsets.only(bottom: Dv.s8),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  final convoId = _chatService.getConversationId(_auth.uid, u.uid);
                                  context.push('/chat/$convoId');
                                },
                                child: Row(
                                  children: [
                                    DvAvatar(name: u.displayName, radius: 20, imageUrl: u.avatarUrl),
                                    const SizedBox(width: Dv.s12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u.displayName, style: Dv.title(size: 14)),
                                        Text('@${u.username}', style: Dv.mono(size: 11, color: Dv.ash)),
                                      ],
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.chat_bubble_outline_rounded, color: Dv.green, size: 18),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const DvLogo(size: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded, color: Dv.green),
            onPressed: _showNewChatDialog,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _chatService.streamUserConversations(_auth.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DvLoadingState(message: 'SYNCING COMMS...');
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return DvEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'NO MESSAGES',
              subtitle: 'Direct tactical comms will appear here.',
              action: OutlinedButton.icon(
                onPressed: _showNewChatDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('START NEW COMM'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Dv.s16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final convo = conversations[index];
              final otherId = convo.getOtherParticipantId(_auth.uid) ?? 'Unknown';
              final shortId = otherId.length > 4 ? otherId.substring(otherId.length - 4) : otherId;

              return TacticalCard(
                margin: const EdgeInsets.only(bottom: Dv.s8),
                onTap: () => context.push('/chat/${convo.id}'),
                child: Row(
                  children: [
                    DvAvatar(name: 'PLAYER $shortId', radius: 24),
                    const SizedBox(width: Dv.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PLAYER $shortId', style: Dv.title(size: 16)),
                          const SizedBox(height: Dv.s4),
                          Text(
                            convo.lastMessage ?? 'Secure channel established.',
                            style: Dv.body(color: Dv.ash),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (convo.lastMessageTime != null)
                      TelemetryLabel(
                        text: _formatTime(convo.lastMessageTime!),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'NOW';
  }
}

