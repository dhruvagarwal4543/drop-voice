import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/theme.dart';
import '../../models/room.dart';
import '../../models/user_profile.dart';
import '../../services/firestore_service.dart';
import '../../services/user_service.dart';
import '../../widgets/dv_logo.dart';
import '../../widgets/dv_avatar.dart';
import '../../widgets/gaming_buttons.dart';
import '../../widgets/tactical_card.dart';
import '../../widgets/telemetry_label.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _firestore = FirestoreService();
  final _userService = UserService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dv.obsidian,
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: _userService.streamProfile(_uid),
          builder: (context, profileSnap) {
            final profile = profileSnap.data;
            final displayName = profile?.displayName ?? 'PLAYER';
            final username = profile != null ? '@${profile.username}' : '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dv.s20, vertical: Dv.s12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const DvLogo(size: 20),
                      Row(
                        children: [
                          const TelemetryLabel(text: 'SECURE LINK', color: Dv.green, dotColor: Dv.green),
                          const SizedBox(width: Dv.s16),
                          DvAvatar(name: displayName, radius: 18, isOnline: true, showPresence: true, imageUrl: profile?.avatarUrl),
                        ],
                      ),
                    ],
                  ),
                ),

                // Hero Section
                Padding(
                  padding: const EdgeInsets.all(Dv.s20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WELCOME BACK,', style: Dv.mono(size: 12, color: Dv.ash)),
                      const SizedBox(height: 4),
                      Text(displayName.toUpperCase(), style: Dv.display(size: 32)),
                      if (username.isNotEmpty) Text(username, style: Dv.mono(size: 13, color: Dv.green)),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dv.s20),
                  child: Row(
                    children: [
                      Expanded(child: PrimaryButton(label: 'CREATE ROOM', icon: Icons.add_circle_outline_rounded, onPressed: () => context.push('/create-room'))),
                      const SizedBox(width: Dv.s12),
                      Expanded(child: SecondaryButton(label: 'JOIN ROOM', icon: Icons.login_rounded, onPressed: () => context.push('/join-room'))),
                    ],
                  ),
                ),

                const SizedBox(height: Dv.s32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dv.s20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TelemetryLabel(text: 'RECENT ROOMS', color: Dv.ash),
                      Icon(Icons.history_rounded, color: Dv.slate, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: Dv.s12),
                Expanded(
                  child: StreamBuilder<List<Room>>(
                    stream: _firestore.streamActiveRooms(),
                    builder: (context, snapshot) {
                      final rooms = snapshot.data ?? [];
                      final myRooms = rooms.where((r) => r.hostId == _uid).toList();

                      if (myRooms.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(Dv.s32),
                            child: Text(
                              'NO RECENT ACTIVITY.\nCREATE OR JOIN A ROOM TO BEGIN.',
                              style: Dv.mono(color: Dv.slate),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: Dv.s20, vertical: Dv.s8),
                        itemCount: myRooms.length,
                        itemBuilder: (context, i) {
                          final room = myRooms[i];
                          return TacticalCard(
                            margin: const EdgeInsets.only(bottom: Dv.s12),
                            greenEdge: true,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(Dv.s12),
                                  decoration: BoxDecoration(color: Dv.charcoal, borderRadius: BorderRadius.circular(Dv.r8)),
                                  child: const Icon(Icons.headset_rounded, color: Dv.green),
                                ),
                                const SizedBox(width: Dv.s16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(room.code, style: Dv.monoLarge(size: 20)),
                                      const SizedBox(height: 4),
                                      TelemetryLabel(text: 'HOSTED BY YOU', color: Dv.ash),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Dv.slate),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
