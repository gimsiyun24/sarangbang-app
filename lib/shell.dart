import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'features/auth/profile_setup_page.dart';
import 'features/auth/room_select_page.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/glass.dart';
import 'widgets/push_sync.dart';

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
      // 내용이 유리 탭바 아래로 지나가게 합니다. 그래서 각 탭 화면은 아래 여백을 탭바 높이만큼 더 둡니다.
      extendBody: true,
      body: PushSync(child: shell),
      bottomNavigationBar: _FloatingTabBar(
        currentIndex: shell.currentIndex,
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

typedef _Tab = ({AppIconData icon, String label});

// 고른 탭은 속을 채운 모양(filled)으로 그립니다.
const List<_Tab> _tabs = [
  (icon: AppIcons.home, label: '홈'),
  (icon: AppIcons.heartHand, label: '기도'),
  (icon: AppIcons.chat, label: '채팅'),
  (icon: AppIcons.calendar, label: '모임'),
  (icon: AppIcons.grid, label: '더보기'),
];

/// 애기애타 앱의 하단 탭바 — 화면 아래에 떠 있는 가로로 긴 알약.
/// 고른 탭 뒤에 회색 알약이 깔리고, 탭을 누르면 그 알약이 미끄러져 갑니다.
/// 회색 알약을 짚어 좌우로 끌어도 탭을 옮길 수 있습니다.
///
/// 애기애타와 달리 내용이 탭바 뒤로 지나가지 않습니다(본문이 탭바 위에서 끝남).
/// 그래서 뒤를 흐리는 유리 효과는 두지 않았습니다.
class _FloatingTabBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FloatingTabBar({required this.currentIndex, required this.onTap});

  @override
  State<_FloatingTabBar> createState() => _FloatingTabBarState();
}

class _FloatingTabBarState extends State<_FloatingTabBar> {
  /// 탭바 높이 (위아래 여백 4px씩 포함). 애기애타 64px에서 실기에서 보고 3px 높임.
  static const _height = 67.0;

  /// 회색 알약과 탭바 테두리 사이 간격. 사방 모두 이 값입니다.
  static const _barPadding = 4.0;

  /// 회색 알약이 한 칸보다 좌우로 더 나오는 길이.
  /// 칸 자체를 이만큼 더 들여둬서, 맨 끝 탭에서도 알약이 사방 4px 자리에 멈춥니다.
  static const _pillBleed = 3.0;

  /// 알약을 짚고 있는 동안 커지는 배율의 상한
  static const _maxGrabScale = 1.1;

  static const _slide = Duration(milliseconds: 220);
  static const _pop = Duration(milliseconds: 180);
  static const _curve = Cubic(0.22, 1, 0.36, 1);

  /// 알약을 짚은 가로 위치. null 이면 알약을 짚지 않은 것입니다.
  double? _startX;

  /// 실제로 끌기 시작했는지 (짚기만 하고 떼면 그냥 누르기입니다)
  bool _dragging = false;

  /// 끌고 있는 동안 알약이 밀려난 거리(px)
  double _dx = 0;

  /// 손을 떼며 옮겨가기로 정한 탭. 주소가 따라오면 놓아줍니다.
  int? _target;

  @override
  void didUpdateWidget(covariant _FloatingTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_target != null && widget.currentIndex == _target) _target = null;
  }

  /// 끌지 않을 때 알약이 앉는 탭
  int get _restIndex => _target ?? widget.currentIndex;

  void _onDown(DragDownDetails d, double slot) {
    // 회색 알약을 짚었을 때만 끌기가 시작됩니다. 다른 탭을 누른 건 그냥 이동입니다.
    final pillStart = widget.currentIndex * slot;
    final x = d.localPosition.dx;
    if (x < pillStart || x > pillStart + slot) return;
    setState(() {
      _startX = x;
      _dx = 0;
    });
  }

  void _onUpdate(DragUpdateDetails d, double slot) {
    final startX = _startX;
    if (startX == null) return;
    // 왼쪽 끝 탭보다 왼쪽으로, 오른쪽 끝 탭보다 오른쪽으로는 나가지 않습니다.
    final i = widget.currentIndex;
    final dx = (d.localPosition.dx - startX)
        .clamp(-i * slot, (_tabs.length - 1 - i) * slot)
        .toDouble();
    setState(() {
      _dragging = true;
      _dx = dx;
    });
  }

  void _onEnd(double slot) {
    if (_startX == null) return;
    // 지나온 칸까지만 갑니다. 반올림하면 한 칸 반에서 아직 닿지도 않은 두 칸째로 넘어갑니다.
    // 한 칸도 못 지났으면 제자리로 미끄러져 돌아갑니다.
    final passed = (_dx / slot).truncate();
    final target = widget.currentIndex + passed;
    setState(() {
      _startX = null;
      _dragging = false;
      _dx = 0;
      if (passed != 0) _target = target;
    });
    if (passed != 0) widget.onTap(target);
  }

  void _onCancel() {
    if (_startX == null) return;
    setState(() {
      _startX = null;
      _dragging = false;
      _dx = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 홈 바가 있는 아이폰에서는 그 위로 띄우고, 없으면 바닥에서 8px 띄웁니다.
    // 끝의 +11 은 실기에서 보고 탭바 전체(알약·아이콘·글씨)를 11px 더 올린 것입니다.
    final bottom =
        math.max(8.0, MediaQuery.viewPaddingOf(context).bottom - 4) + 11;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 6, 20, bottom),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: GlassSurface(
            height: _height,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            padding: const EdgeInsets.symmetric(
                vertical: _barPadding, horizontal: _barPadding + _pillBleed),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = _tabs.length;
                final slot = constraints.maxWidth / count;
                final pillWidth = slot + _pillBleed * 2;

                // 맨 끝 탭에서 알약과 탭바 테두리 사이 여유는 좌우 4px뿐이라,
                // 넓은 화면에서도 그 여유를 넘지 않을 만큼만 키웁니다.
                final grabScale = math.min(
                    _maxGrabScale, 1 + (_barPadding * 2) / pillWidth);

                // 파랗게 켜둘 탭 — 끄는 동안에는 손을 떼면 가게 될 탭입니다.
                final covered = _dragging
                    ? math.min(count - 1,
                        math.max(0, widget.currentIndex + (_dx / slot).truncate()))
                    : _restIndex;

                // 끄는 동안에는 손가락에 바로 붙고(애니메이션 없음),
                // 손을 떼거나 탭을 누르면 부드럽게 미끄러집니다.
                final pillLeft = (_dragging
                        ? widget.currentIndex * slot + _dx
                        : _restIndex * slot) -
                    _pillBleed;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  dragStartBehavior: DragStartBehavior.down,
                  onHorizontalDragDown: (d) => _onDown(d, slot),
                  onHorizontalDragUpdate: (d) => _onUpdate(d, slot),
                  onHorizontalDragEnd: (_) => _onEnd(slot),
                  onHorizontalDragCancel: _onCancel,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedPositioned(
                        duration: _dragging ? Duration.zero : _slide,
                        curve: _curve,
                        top: 0,
                        bottom: 0,
                        left: pillLeft,
                        width: pillWidth,
                        child: AnimatedScale(
                          scale: _startX != null ? grabScale : 1,
                          duration: _pop,
                          curve: _curve,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.ink.withValues(alpha: 0.07),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35)),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < count; i++)
                            Expanded(
                              child: _TabItem(
                                tab: _tabs[i],
                                lit: i == covered,
                                selected: i == widget.currentIndex,
                                onTap: () => widget.onTap(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
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

  /// 회색 알약이 덮고 있어 파랗게 켜진 탭 (끄는 동안에는 지금 탭과 다를 수 있음)
  final bool lit;
  final bool selected;
  final VoidCallback onTap;
  const _TabItem({
    required this.tab,
    required this.lit,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = lit ? AppColors.brand : AppColors.inkSoft;
    return Semantics(
      button: true,
      selected: selected,
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
              AppIcon(tab.icon, filled: lit, size: 27, color: color),
              const SizedBox(height: 1),
              Text(
                tab.label,
                style: AppText.tab.copyWith(
                  color: color,
                  fontWeight: lit ? FontWeight.w700 : FontWeight.w500,
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
            icon: AppIcon(AppIcons.chevronLeft,
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
