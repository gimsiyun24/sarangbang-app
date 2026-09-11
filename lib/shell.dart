import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'features/auth/profile_setup_page.dart';
import 'features/auth/room_select_page.dart';
import 'theme.dart';
import 'widgets/common.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider);
    final uid = ref.watch(myUidProvider);

    if (uid != null && members.hasValue) {
      final me = ref.watch(memberMapProvider)[uid];
      // 1) 첫 로그인 → 이름/별칭·생일
      if (me == null || !me.isProfileComplete) {
        return const ProfileSetupPage();
      }
      // 2) 분반 사랑방 고르기
      if (!me.hasRoom) {
        return const RoomSelectPage();
      }
    }
    if (members.hasError) {
      return Scaffold(body: ErrorNote(members.error!));
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: AppShadow.nav,
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: '홈'),
              NavigationDestination(
                  icon: Icon(Icons.volunteer_activism_outlined),
                  selectedIcon: Icon(Icons.volunteer_activism_rounded),
                  label: '기도'),
              NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: '채팅'),
              NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: '모임'),
              NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: '더보기'),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하위 페이지 공통 스캐폴드 (뒤로가기 있는 화면)
class SubPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? fab;
  final String? fallbackRoute;

  const SubPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.fab,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title, overflow: TextOverflow.ellipsis),
          titleSpacing: 4,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(fallbackRoute ?? '/more'),
          ),
          actions: [...?actions, const SizedBox(width: 6)],
        ),
        floatingActionButton: fab,
        body: SafeArea(child: Bounded(child: body)),
      );
}
