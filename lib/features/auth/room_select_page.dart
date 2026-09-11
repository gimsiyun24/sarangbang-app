import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// 첫 진입 — 어느 분반 사랑방인지 고릅니다.
/// 전체 사랑방은 고를 필요 없이 모두 자동으로 들어갑니다.
class RoomSelectPage extends ConsumerStatefulWidget {
  const RoomSelectPage({super.key});
  @override
  ConsumerState<RoomSelectPage> createState() => _RoomSelectPageState();
}

class _RoomSelectPageState extends ConsumerState<RoomSelectPage> {
  String? _picked;
  bool _busy = false;

  Future<void> _save() async {
    final uid = ref.read(myUidProvider);
    if (uid == null || _picked == null) return;
    setState(() => _busy = true);
    try {
      await Refs.member(uid).set(
        {'roomId': _picked, 'roomJoinedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      if (mounted) toast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(myMemberProvider);
    final members = ref.watch(membersProvider).value ?? const [];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🏡', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('${me?.display ?? ''}님,\n어느 사랑방인가요?',
                      style: AppText.display),
                  const SizedBox(height: 8),
                  Text('기도제목과 신앙루틴은 여기서 나눠요.',
                      style: AppText.body.copyWith(color: AppColors.inkMuted)),
                  const SizedBox(height: 26),

                  for (final r in AppConfig.classRooms) ...[
                    _RoomCard(
                      room: r,
                      selected: _picked == r.id,
                      memberCount:
                          members.where((m) => m.roomId == r.id).length,
                      onTap: () => setState(() => _picked = r.id),
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '전체 사랑방에는 자동으로 들어갑니다.\n분반과 전체를 언제든 오갈 수 있어요.',
                            style: AppText.caption,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: (_busy || _picked == null) ? null : _save,
                    child: Text(_busy ? '들어가는 중...' : '이 사랑방으로 시작하기'),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('나중에 더보기 → 내 프로필에서 바꿀 수 있어요',
                        style: AppText.micro),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final SarangRoom room;
  final bool selected;
  final int memberCount;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.selected,
    required this.memberCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand50 : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.brand : AppColors.line,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected ? null : AppShadow.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name, style: AppText.cardTitle),
                  const SizedBox(height: 3),
                  Text(
                    memberCount == 0 ? '첫 멤버가 되어요' : '$memberCount명',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: selected ? 1 : 0,
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.brand, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
