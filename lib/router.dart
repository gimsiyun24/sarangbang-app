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
import 'features/more/notifications_page.dart';
import 'features/more/polls_page.dart';
import 'features/more/profile_page.dart';
import 'features/more/sermon_notes_page.dart';
import 'features/more/settings_page.dart';
import 'features/more/settlements_page.dart';
import 'features/prayer/prayer_page.dart';
import 'shell.dart';
import 'widgets/swipe_back.dart';

/// `<` 가 있는 화면(SubPage) 은 모두 이걸로 엽니다 — 오른쪽으로 밀면 앞 화면으로 돌아갑니다.
/// 탭 화면 5개는 돌아갈 앞 화면이 없으므로 그대로 둡니다.
Page<dynamic> _sub(GoRouterState state, Widget child) =>
    SwipeBackPage<dynamic>(key: state.pageKey, name: state.name, child: child);

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
      // 모든 탭 제목 줄의 아이콘(알림·내 프로필·설정)으로 들어오는 화면.
      // 탭 위로 올라오고(push), 뒤로 가면 원래 있던 탭으로 돌아갑니다.
      GoRoute(
          path: '/notifications',
          pageBuilder: (c, s) => _sub(s, const NotificationsPage())),
      GoRoute(path: '/profile', pageBuilder: (c, s) => _sub(s, const ProfilePage())),
      GoRoute(path: '/settings', pageBuilder: (c, s) => _sub(s, const SettingsPage())),
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
                  pageBuilder: (c, s) => _sub(
                    s,
                    MeetingDetailPage(
                      roomId: s.pathParameters['roomId']!,
                      meetingId: s.pathParameters['id']!,
                    ),
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
                  pageBuilder: (c, s) => _sub(s, const AlbumsPage()),
                  routes: [
                    GoRoute(
                      path: ':roomId/:id',
                      pageBuilder: (c, s) => _sub(
                        s,
                        AlbumDetailPage(
                          roomId: s.pathParameters['roomId']!,
                          albumId: s.pathParameters['id']!,
                        ),
                      ),
                    ),
                  ],
                ),
                GoRoute(
                    path: 'notices', pageBuilder: (c, s) => _sub(s, const NoticesPage())),
                GoRoute(
                    path: 'notes', pageBuilder: (c, s) => _sub(s, const SermonNotesPage())),
                GoRoute(
                    path: 'members', pageBuilder: (c, s) => _sub(s, const MembersPage())),
                GoRoute(path: 'polls', pageBuilder: (c, s) => _sub(s, const PollsPage())),
                GoRoute(
                    path: 'settlements',
                    pageBuilder: (c, s) => _sub(s, const SettlementsPage())),
                GoRoute(
                    path: 'profile', pageBuilder: (c, s) => _sub(s, const ProfilePage())),
                GoRoute(path: 'admin', pageBuilder: (c, s) => _sub(s, const AdminPage())),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
}
