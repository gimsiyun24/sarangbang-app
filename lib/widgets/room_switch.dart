import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_config.dart';
import '../core/providers.dart';
import '../theme.dart';
import 'common.dart';

/// 앱바에 붙는 사랑방 전환 칩. 내 분반 ↔ 전체 사랑방.
class RoomSwitchChip extends ConsumerWidget {
  final bool compact;
  const RoomSwitchChip({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(currentRoomProvider);
    final rooms = ref.watch(myRoomsProvider);

    return InkWell(
      onTap: rooms.length < 2 ? null : () => _open(context, ref),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: EdgeInsets.fromLTRB(11, 7, rooms.length < 2 ? 12 : 7, 7),
        decoration: BoxDecoration(
          color: room.isAll ? AppColors.brand50 : AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              compact ? room.name.replaceAll('사랑방', '') : room.name,
              style: AppText.label.copyWith(
                  fontSize: 13, color: AppColors.brand),
            ),
            if (rooms.length >= 2)
              const Icon(Icons.unfold_more_rounded,
                  size: 15, color: AppColors.brand),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    final current = ref.read(currentRoomIdProvider);
    openSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle('사랑방 이동'),
          for (final r in ref.read(myRoomsProvider)) ...[
            _RoomRow(
              name: r.name,
              subtitle: r.isAll
                  ? '청년부 전체가 모이는 곳'
                  : '기도제목·신앙루틴을 나누는 우리 분반',
              selected: r.id == current,
              onTap: () {
                switchRoom(ref, r.id);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Text(
            '기도제목과 신앙루틴은 어느 방에서 보든\n항상 내 분반 사랑방 것만 오갑니다.',
            textAlign: TextAlign.center,
            style: AppText.micro,
          ),
        ],
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  final String name, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoomRow({
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand50 : AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: selected ? AppColors.brand : Colors.transparent,
                width: 1.6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.bodyStrong),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.micro),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.brand, size: 21),
            ],
          ),
        ),
      );
}

/// "이건 어느 사랑방 건지" 표시하는 작은 뱃지
class RoomBadge extends StatelessWidget {
  final String roomId;
  const RoomBadge(this.roomId, {super.key});

  @override
  Widget build(BuildContext context) {
    final r = AppConfig.roomOf(roomId);
    return Pill(
      r.name,
      bg: r.isAll ? AppColors.brand50 : AppColors.fill,
    );
  }
}
