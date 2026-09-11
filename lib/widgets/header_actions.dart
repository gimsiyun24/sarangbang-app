import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/inbox.dart';
import '../theme.dart';
import 'app_icon.dart';
import 'app_icons.dart';

/// 제목 줄 오른쪽의 단추 세 개 — 알림함, 내 프로필, 설정. 애기애타 앱의 HeaderActions 와 같습니다.
///
/// 단추는 손끝이 닿아야 해서 40px인데 아이콘은 27px이라, 사이를 0으로 붙여도 아이콘끼리
/// 13px 떨어져 보입니다. 그래서 단추를 6px씩 겹쳐 아이콘 사이를 7px로 좁혔습니다.
/// 맨 오른쪽 단추의 빈 여백은 쓰는 쪽에서 4px 당겨 카드 끝과 맞춥니다.
///
/// 세 화면은 탭 위로 올라오고(push), 뒤로 가면 원래 있던 탭으로 돌아갑니다.
class HeaderActions extends ConsumerWidget {
  const HeaderActions({super.key});

  static const _button = 40.0;
  static const _overlap = 6.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNew = ref.watch(inboxHasNewProvider);
    final buttons = [
      _HeaderIconButton(
        icon: AppIcons.bell,
        label: hasNew ? '알림 열기 (새 알림 있음)' : '알림 열기',
        route: '/notifications',
        dot: hasNew,
      ),
      const _HeaderIconButton(icon: AppIcons.person, label: '내 프로필 열기', route: '/profile'),
      const _HeaderIconButton(icon: AppIcons.settings, label: '설정 열기', route: '/settings'),
    ];

    return SizedBox(
      width: _button * buttons.length - _overlap * (buttons.length - 1),
      height: _button,
      child: Stack(
        children: [
          for (var i = 0; i < buttons.length; i++)
            Positioned(
              left: i * (_button - _overlap),
              top: 0,
              width: _button,
              height: _button,
              child: buttons[i],
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final AppIconData icon;
  final String label, route;
  final bool dot;

  const _HeaderIconButton({
    required this.icon,
    required this.label,
    required this.route,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push(route),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppIcon(icon, size: 27, color: AppColors.inkSoft),
                // 새 알림 표시 — 개수가 아니라 빨간 점 하나. 둘레의 바탕색 테가 점을 아이콘 선에서 떼어 놓습니다.
                if (dot)
                  Positioned(
                    top: 5,
                    right: 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.canvas, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
