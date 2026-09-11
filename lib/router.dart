import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/album/album_detail_page.dart';
import 'features/album/albums_page.dart';
import 'features/auth/login_page.dart';
import 'features/chat/chat_page.dart';
import 'features/home/home_page.dart';
import 'features/meeting/meeting_detail_page.dart';
import 'features/meeting/meetings_page.dart';
import 'features/more/admin_page.dart';
import 'features/more/members_page.dart';
import 'features/more/more_page.dart';
import 'features/more/notices_page.dart';
import 'features/more/polls_page.dart';
import 'features/more/profile_page.dart';
import 'features/more/sermon_notes_page.dart';
import 'features/more/settlements_page.dart';
import 'features/prayer/prayer_page.dart';
import 'shell.dart';

/// FirebaseAuth 스트림을 go_router 의 refreshListenable 로 연결
class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription<User?> _sub;
  _AuthRefresh() {
    _sub =
        FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  final refresh = _AuthRefresh();

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = FirebaseAuth.instance.currentUser != null;
      final atLogin = state.matchedLocation == '/login';
      if (!signedIn) return atLogin ? null : '/login';
      if (atLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (c, s, navShell) => AppShell(shell: navShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (c, s) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/prayer', builder: (c, s) => const PrayerPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/chat', builder: (c, s) => const ChatPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/meetings',
              builder: (c, s) => const MeetingsPage(),
              routes: [
                GoRoute(
                  path: ':roomId/:id',
                  builder: (c, s) => MeetingDetailPage(
                    roomId: s.pathParameters['roomId']!,
                    meetingId: s.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              builder: (c, s) => const MorePage(),
              routes: [
                GoRoute(
                  path: 'albums',
                  builder: (c, s) => const AlbumsPage(),
                  routes: [
                    GoRoute(
                      path: ':roomId/:id',
                      builder: (c, s) => AlbumDetailPage(
                        roomId: s.pathParameters['roomId']!,
                        albumId: s.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
                GoRoute(path: 'notices', builder: (c, s) => const NoticesPage()),
                GoRoute(path: 'notes', builder: (c, s) => const SermonNotesPage()),
                GoRoute(path: 'members', builder: (c, s) => const MembersPage()),
                GoRoute(path: 'polls', builder: (c, s) => const PollsPage()),
                GoRoute(
                    path: 'settlements',
                    builder: (c, s) => const SettlementsPage()),
                GoRoute(path: 'profile', builder: (c, s) => const ProfilePage()),
                GoRoute(path: 'admin', builder: (c, s) => const AdminPage()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}
