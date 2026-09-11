import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/display_settings.dart';
import '../../core/providers.dart';
import '../../core/push.dart';
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
    final brightness = ref.watch(resolvedBrightnessProvider);
    final isLeader = ref.watch(isLeaderProvider);

    return SubPage(
      title: '설정',
      fallbackRoute: '/home',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          const _PushSection(),

          const SizedBox(height: 28),
          const _Title('글씨 크기'),
          // 칸마다 그 크기로 글씨를 써서, 고르기 전에도 어떻게 될지 보입니다.
          SegmentedControl<TextSize>(
            options: [
              for (final s in TextSize.values)
                SegmentOption(s, s.label, fontSize: s.previewFontSize),
            ],
            value: textSize,
            onChanged: ref.read(textSizeProvider.notifier).set,
          ),

          const SizedBox(height: 28),
          const _Title('화면'),
          // 두 칸뿐입니다. 아무것도 안 고른 상태가 이미 "폰 설정 따라가기"라 그 칸은 두지 않았습니다.
          // 파란 상자는 고른 값이 아니라 지금 실제로 보이는 밝기에 앉습니다.
          SegmentedControl<Brightness>(
            options: const [
              SegmentOption(Brightness.light, '밝게'),
              SegmentOption(Brightness.dark, '어둡게'),
            ],
            value: brightness,
            onChanged: ref.read(themeChoiceProvider.notifier).set,
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
                  AppIcon(AppIcons.chevronRight, size: 20, color: AppColors.inkFaint),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) =>
      SectionTitle(text, padding: const EdgeInsets.fromLTRB(0, 8, 0, 12));
}

/// 알림 켜기/끄기 — 글씨 크기·화면과 같은 모양의 고르개입니다.
///
/// 이 설정은 **기기마다 따로**입니다. 폰에서 켜도 태블릿에서는 따로 켜야 합니다(브라우저 권한이 기기 단위).
/// 켜고 끄는 데 시간이 걸리고(권한을 묻고 토큰을 받아옵니다) 실패도 하므로,
/// 누르는 동안은 고르개를 잠그고 막힌 이유를 아래에 적습니다.
class _PushSection extends ConsumerStatefulWidget {
  const _PushSection();

  @override
  ConsumerState<_PushSection> createState() => _PushSectionState();
}

class _PushSectionState extends ConsumerState<_PushSection> {
  bool _pending = false;
  String? _problem;

  Future<void> _choose(bool turnOn, bool isOn) async {
    final uid = ref.read(myUidProvider);
    if (_pending || uid == null || turnOn == isOn) return;
    setState(() {
      _pending = true;
      _problem = null;
    });
    try {
      if (turnOn) {
        final permission = await enablePush(uid);
        if (permission != PushPermission.granted) _problem = pushPermissionProblem(permission);
      } else {
        await disablePush();
      }
    } catch (e) {
      _problem = '알림을 켜지 못했어요. 잠시 후 다시 시도해 주세요.';
    } finally {
      ref.invalidate(pushStateProvider);
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pushStateProvider).value;
    final on = state?.on ?? false;
    final message = state?.blocked ?? _problem;
    final locked = _pending || state == null || state.blocked != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title('알림'),
        Opacity(
          opacity: locked ? 0.5 : 1,
          child: IgnorePointer(
            ignoring: locked,
            child: SegmentedControl<bool>(
              options: const [SegmentOption(false, '끄기'), SegmentOption(true, '켜기')],
              value: on,
              onChanged: (next) => _choose(next, on),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 10),
          Text(message,
              style: AppText.caption.copyWith(color: AppColors.danger, height: 1.55)),
        ],
      ],
    );
  }
}
