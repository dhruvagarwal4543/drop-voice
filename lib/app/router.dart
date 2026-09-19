import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/startup/startup_page.dart';
import '../features/login/login_page.dart';
import '../features/home/home_page.dart';
import '../features/squad/squad_page.dart';
import '../features/rooms/rooms_page.dart';
import '../features/messages/messages_page.dart';
import '../features/profile/profile_page.dart';
import '../features/create_room/create_room_page.dart';
import '../features/join_room/join_room_page.dart';
import '../features/room/room_page.dart';
import '../features/messages/chat_page.dart';
import '../widgets/dv_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorSquadKey = GlobalKey<NavigatorState>(debugLabel: 'squad');
final _shellNavigatorRoomsKey = GlobalKey<NavigatorState>(debugLabel: 'rooms');
final _shellNavigatorMessagesKey = GlobalKey<NavigatorState>(debugLabel: 'messages');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const StartupPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    
    // Full screen routes (no nav bar)
    GoRoute(
      path: '/chat/:conversationId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        return ChatPage(conversationId: state.pathParameters['conversationId']!);
      },
    ),
    GoRoute(
      path: '/create-room',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateRoomPage(),
    ),
    GoRoute(
      path: '/join-room',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const JoinRoomPage(),
    ),
    GoRoute(
      path: '/room/:roomCode',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final roomCode = state.pathParameters['roomCode']!;
        final extra = state.extra as Map<String, dynamic>?;
        return RoomPage(
          roomCode: roomCode,
          token: extra?['token'] as String? ?? '',
          livekitUrl: extra?['livekitUrl'] as String? ?? '',
        );
      },
    ),

    // Shell routes (with nav bar)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomeKey,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSquadKey,
          routes: [
            GoRoute(
              path: '/squad',
              builder: (context, state) => const SquadPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorRoomsKey,
          routes: [
            GoRoute(
              path: '/rooms',
              builder: (context, state) => const RoomsPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorMessagesKey,
          routes: [
            GoRoute(
              path: '/messages',
              builder: (context, state) => const MessagesPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorProfileKey,
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
