import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/friendship.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../widgets/dv_avatar.dart';
import '../../widgets/dv_logo.dart';
import '../../widgets/dv_text_field.dart';
import '../../widgets/state_widgets.dart';
import '../../widgets/tactical_card.dart';
import '../../widgets/telemetry_label.dart';

class SquadPage extends StatefulWidget {
  const SquadPage({super.key});

  @override
  State<SquadPage> createState() => _SquadPageState();
}

class _SquadPageState extends State<SquadPage> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _userService = UserService();
  late final TabController _tabCtrl;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    try { _myUid = _auth.uid; } catch (_) {}
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserSearchSheet(myUid: _myUid!, userService: _userService),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_myUid == null) {
      return const Scaffold(backgroundColor: Dv.obsidian, body: DvEmptyState(icon: Icons.person_off_rounded, title: 'NOT SIGNED IN'));
    }

    return Scaffold(
      backgroundColor: Dv.obsidian,
      appBar: AppBar(
        title: const DvLogo(size: 20),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded, color: Dv.green),
            onPressed: _showSearchDialog,
            tooltip: 'Find Players',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: Dv.mono(size: 12),
          indicatorColor: Dv.green,
          tabs: const [
            Tab(text: 'FRIENDS'),
            Tab(text: 'REQUESTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _FriendsTab(myUid: _myUid!, userService: _userService),
          _RequestsTab(myUid: _myUid!, userService: _userService),
        ],
      ),
    );
  }
}

// ─── Friends Tab ──────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  const _FriendsTab({required this.myUid, required this.userService});
  final String myUid;
  final UserService userService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserProfile>>(
      stream: userService.streamFriends(myUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const DvLoadingState(message: 'SYNCING SQUAD...');
        }
        final friends = snap.data ?? [];
        if (friends.isEmpty) {
          return DvEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'NO SQUAD YET',
            subtitle: 'Search for players by username\nand send friend requests.',
            action: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('FIND PLAYERS'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(Dv.s16),
          itemCount: friends.length,
          itemBuilder: (context, i) {
            final f = friends[i];
            return _FriendCard(profile: f, myUid: myUid, userService: userService);
          },
        );
      },
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.profile, required this.myUid, required this.userService});
  final UserProfile profile;
  final String myUid;
  final UserService userService;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (profile.status) {
      UserStatus.online => ('ONLINE', Dv.green),
      UserStatus.inRoom => ('IN ROOM', Colors.amber),
      UserStatus.offline => ('OFFLINE', Dv.ash),
    };

    return TacticalCard(
      margin: const EdgeInsets.only(bottom: Dv.s8),
      child: Row(
        children: [
          DvAvatar(name: profile.displayName, radius: 24, imageUrl: profile.avatarUrl),
          const SizedBox(width: Dv.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName, style: Dv.title(size: 15)),
                Row(
                  children: [
                    Text('@${profile.username}', style: Dv.mono(size: 11, color: Dv.ash)),
                    const SizedBox(width: Dv.s8),
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    TelemetryLabel(text: statusLabel, color: statusColor),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Dv.ash, size: 18),
            color: Dv.graphite,
            onSelected: (val) async {
              if (val == 'message') {
                final convoId = '${[myUid, profile.uid]..sort()}'.replaceAll('[', '').replaceAll(']', '').replaceAll(', ', '_');
                context.push('/chat/$convoId');
              } else if (val == 'remove') {
                await userService.removeFriend(myUid, profile.uid);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'message', child: Text('MESSAGE', style: Dv.body(color: Dv.white))),
              PopupMenuItem(value: 'remove', child: Text('REMOVE', style: Dv.body(color: Dv.crimson))),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Requests Tab ─────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({required this.myUid, required this.userService});
  final String myUid;
  final UserService userService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Friendship>>(
      stream: userService.streamFriendships(myUid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const DvLoadingState(message: 'LOADING...');
        }
        final all = snap.data ?? [];
        final incoming = all.where((f) => f.status == FriendshipStatus.pending && f.toUid == myUid).toList();
        final outgoing = all.where((f) => f.status == FriendshipStatus.pending && f.fromUid == myUid).toList();

        if (incoming.isEmpty && outgoing.isEmpty) {
          return const DvEmptyState(icon: Icons.inbox_rounded, title: 'NO PENDING REQUESTS');
        }

        return ListView(
          padding: const EdgeInsets.all(Dv.s16),
          children: [
            if (incoming.isNotEmpty) ...[
              TelemetryLabel(text: 'INCOMING (${incoming.length})'),
              const SizedBox(height: Dv.s8),
              ...incoming.map((f) => _RequestCard(friendship: f, myUid: myUid, userService: userService, isIncoming: true)),
              const SizedBox(height: Dv.s16),
            ],
            if (outgoing.isNotEmpty) ...[
              TelemetryLabel(text: 'SENT (${outgoing.length})'),
              const SizedBox(height: Dv.s8),
              ...outgoing.map((f) => _RequestCard(friendship: f, myUid: myUid, userService: userService, isIncoming: false)),
            ],
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({required this.friendship, required this.myUid, required this.userService, required this.isIncoming});
  final Friendship friendship;
  final String myUid;
  final UserService userService;
  final bool isIncoming;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    final otherUid = widget.isIncoming ? widget.friendship.fromUid : widget.friendship.toUid;
    widget.userService.getProfile(otherUid).then((p) {
      if (mounted && p != null) setState(() => _profile = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final name = profile?.displayName ?? 'Loading...';

    return TacticalCard(
      margin: const EdgeInsets.only(bottom: Dv.s8),
      child: Row(
        children: [
          DvAvatar(name: name, radius: 20, imageUrl: profile?.avatarUrl),
          const SizedBox(width: Dv.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Dv.title(size: 14)),
                if (profile != null) Text('@${profile.username}', style: Dv.mono(size: 11, color: Dv.ash)),
              ],
            ),
          ),
          if (widget.isIncoming) ...[
            IconButton(
              icon: const Icon(Icons.check_circle_rounded, color: Dv.green, size: 28),
              onPressed: () => widget.userService.acceptFriendRequest(widget.friendship.fromUid, widget.friendship.toUid),
              tooltip: 'Accept',
            ),
            IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Dv.crimson, size: 28),
              onPressed: () => widget.userService.removeFriend(widget.friendship.fromUid, widget.friendship.toUid),
              tooltip: 'Reject',
            ),
          ] else
            TextButton(
              onPressed: () => widget.userService.removeFriend(widget.myUid, widget.friendship.toUid),
              child: Text('CANCEL', style: Dv.button(color: Dv.ash, size: 12)),
            ),
        ],
      ),
    );
  }
}

// ─── User Search Bottom Sheet ─────────────────────────────

class _UserSearchSheet extends StatefulWidget {
  const _UserSearchSheet({required this.myUid, required this.userService});
  final String myUid;
  final UserService userService;

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final _ctrl = TextEditingController();
  List<UserProfile> _results = [];
  bool _isSearching = false;
  Map<String, FriendshipStatus?> _friendStatus = {};

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await widget.userService.searchByUsername(query);
      final filtered = results.where((u) => u.uid != widget.myUid).toList();

      // Check friendship status for each result
      final statuses = <String, FriendshipStatus?>{};
      for (final u in filtered) {
        final f = await widget.userService.getFriendship(widget.myUid, u.uid);
        statuses[u.uid] = f?.status;
      }

      if (mounted) setState(() { _results = filtered; _friendStatus = statuses; _isSearching = false; });
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Dv.graphite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: Dv.s24, right: Dv.s24, top: Dv.s24,
        bottom: MediaQuery.of(context).viewInsets.bottom + Dv.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Dv.steel, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: Dv.s20),
          Text('FIND PLAYERS', style: Dv.headline(size: 18)),
          const SizedBox(height: Dv.s16),
          DvTextField(
            controller: _ctrl,
            hintText: 'Search by username...',
            onChanged: _search,
          ),
          const SizedBox(height: Dv.s12),
          if (_isSearching)
            const Padding(padding: EdgeInsets.all(Dv.s16), child: CircularProgressIndicator(color: Dv.green, strokeWidth: 2))
          else if (_results.isEmpty && _ctrl.text.length >= 2)
            Padding(
              padding: const EdgeInsets.all(Dv.s16),
              child: Text('No players found.', style: Dv.body(color: Dv.ash)),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final user = _results[i];
                  final status = _friendStatus[user.uid];
                  return _SearchResultCard(
                    profile: user,
                    friendStatus: status,
                    onAdd: () async {
                      await widget.userService.sendFriendRequest(widget.myUid, user.uid);
                      if (mounted) setState(() => _friendStatus[user.uid] = FriendshipStatus.pending);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.profile, required this.friendStatus, required this.onAdd});
  final UserProfile profile;
  final FriendshipStatus? friendStatus;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (profile.status) {
      UserStatus.online => ('ONLINE', Dv.green),
      UserStatus.inRoom => ('IN ROOM', Colors.amber),
      UserStatus.offline => ('OFFLINE', Dv.ash),
    };

    Widget trailing;
    if (friendStatus == FriendshipStatus.accepted) {
      trailing = TelemetryLabel(text: 'FRIENDS', color: Dv.green);
    } else if (friendStatus == FriendshipStatus.pending) {
      trailing = TelemetryLabel(text: 'PENDING', color: Colors.amber);
    } else {
      trailing = TextButton(
        onPressed: onAdd,
        child: Text('ADD', style: Dv.button(color: Dv.green, size: 13)),
      );
    }

    return TacticalCard(
      margin: const EdgeInsets.only(bottom: Dv.s8),
      child: Row(
        children: [
          DvAvatar(name: profile.displayName, radius: 22, imageUrl: profile.avatarUrl),
          const SizedBox(width: Dv.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.displayName, style: Dv.title(size: 14)),
                Row(
                  children: [
                    Text('@${profile.username}', style: Dv.mono(size: 11, color: Dv.ash)),
                    const SizedBox(width: Dv.s8),
                    Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    TelemetryLabel(text: statusLabel, color: statusColor),
                  ],
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
