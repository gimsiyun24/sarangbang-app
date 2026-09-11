import 'dart:math' as math;

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
      bottomNavigationBar: _FloatingTabBar(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

typedef _Tab = ({IconData icon, IconData activeIcon, String label});

const List<_Tab> _tabs = [
  (icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: '홈'),
  (
    icon: Icons.volunteer_activism_outlined,
    activeIcon: Icons.volunteer_activism_rounded,
    label: '기도'
  ),
  (
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: '채팅'
  ),
  (
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month_rounded,
    label: '모임'
  ),
  (
    icon: Icons.grid_view_outlined,
    activeIcon: Icons.grid_view_rounded,
    label: '더보기'
  ),
];

/// 애기애타 앱의 하단 탭바 — 화면 아래에 떠 있는 가로로 긴 알약.
/// 고른 탭 뒤에 회색 알약이 깔리고, 탭을 옮기면 그 알약이 미끄러져 갑니다.
///
/// 애기애타와 달리 내용이 탭바 뒤로 지나가지 않습니다(본문이 탭바 위에서 끝남).
/// 그래서 뒤를 흐리는 유리 효과는 두지 않았습니다.
class _FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingTabBar({required this.currentIndex, required this.onTap});

  /// 탭바 높이 (위아래 여백 4px씩 포함)
  static const _height = 64.0;

  /// 회색 알약과 탭바 테두리 사이 간격. 사방 모두 이 값입니다.
  static const _barPadding = 4.0;

  /// 회색 알약이 한 칸보다 좌우로 더 나오는 길이.
  /// 칸 자체를 이만큼 더 들여둬서, 맨 끝 탭에서도 알약이 사방 4px 자리에 멈춥니다.
  static const _pillBleed = 3.0;

  static const _slide = Duration(milliseconds: 220);
  static const _curve = Cubic(0.22, 1, 0.36, 1);

  @override
  Widget build(BuildContext context) {
    // 홈 바가 있는 아이폰에서는 그 위로 띄우고, 없으면 바닥에서 8px 띄웁니다.
    final bottom = math.max(8.0, MediaQuery.viewPaddingOf(context).bottom - 4);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 6, 20, bottom),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            height: _height,
            padding: const EdgeInsets.symmetric(
                vertical: _barPadding, horizontal: _barPadding + _pillBleed),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadow.float,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slot = constraints.maxWidth / _tabs.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: _slide,
                      curve: _curve,
                      top: 0,
                      bottom: 0,
                      left: currentIndex * slot - _pillBleed,
                      width: slot + _pillBleed * 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35)),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          Expanded(
                            child: _TabItem(
                              tab: _tabs[i],
                              active: i == currentIndex,
                              onTap: () => onTap(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final _Tab tab;
  final bool active;
  final VoidCallback onTap;
  const _TabItem({required this.tab, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand : AppColors.inkSoft;
    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 아이콘과 글씨 덩어리를 가운데보다 2px 위에 세웁니다. 눈에는 이쪽이 가운데로 보입니다.
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? tab.activeIcon : tab.icon, size: 27, color: color),
              const SizedBox(height: 1),
              Text(
                tab.label,
                style: AppText.tab.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
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
          // 애기애타처럼 화살표는 화면 끝에서 12px쯤, 제목은 56px에서 시작합니다.
          titleSpacing: 0,
          leadingWidth: 56,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                size: 30, color: AppColors.ink),
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
