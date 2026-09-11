import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/display_settings.dart';
import '../../core/providers.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/segmented_control.dart';

/// 설정 — 제목 줄 톱니로 들어오는 화면. 애기애타 설정 화면과 같은 모양입니다.
///
/// 여기서 고른 값은 이 기기에만 남습니다. 다른 기기에서 열면 그 기기의 설정을 따릅니다.
/// 맨 아래 사랑방 관리로 가는 문만 예외로, 방장에게만 보입니다.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSize = ref.watch(textSizeProvider);
    final isLeader = ref.watch(isLeaderProvider);

    return SubPage(
      title: '설정',
      fallbackRoute: '/home',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          const SectionTitle('글씨 크기', padding: EdgeInsets.fromLTRB(0, 8, 0, 12)),
          // 칸마다 그 크기로 글씨를 써서, 고르기 전에도 어떻게 될지 보입니다.
          SegmentedControl<TextSize>(
            options: [
              for (final s in TextSize.values)
                SegmentOption(s, s.label, fontSize: s.previewFontSize),
            ],
            value: textSize,
            onChanged: ref.read(textSizeProvider.notifier).set,
          ),

          // 방장에게만 보이는 줄. 눌러서 넘어가는 문이라 칸에 적힌 이름이 곧 제목입니다.
          if (isLeader) ...[
            const SizedBox(height: 28),
            SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              onTap: () => context.go('/more/admin'),
              child: Row(
                children: [
                  Expanded(
                    child: Text('사랑방 관리',
                        style: AppText.bodyStrong.copyWith(fontSize: 17)),
                  ),
                  const AppIcon(AppIcons.chevronRight,
                      size: 20, color: AppColors.inkFaint),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
