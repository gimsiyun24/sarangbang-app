import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../models/models.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/room_switch.dart';
import 'meetings_page.dart';

class MeetingDetailPage extends ConsumerWidget {
  final String roomId, meetingId;
  const MeetingDetailPage(
      {super.key, required this.roomId, required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(meetingsProvider(roomId)).value;
    final meeting =
        list?.where((m) => m.id == meetingId).firstOrNull;
    final uid = ref.watch(myUidProvider);

    if (list == null) {
      return const SubPage(title: '모임', body: Loading());
    }
    if (meeting == null) {
      return const SubPage(
        title: '모임',
        body: EmptyState(emoji: '🔍', title: '삭제되었거나 없는 모임이에요'),
      );
    }

    final att =
        ref.watch(attendanceProvider((roomId, meetingId))).value ?? const {};
    final members = ref.watch(roomMembersProvider(roomId));
    final mine = attendFrom(att[uid]?['status'] as String?);

    return SubPage(
      title: meeting.title,
      fallbackRoute: '/meetings',
      actions: [
        if (meeting.authorUid == uid)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) async {
              if (v == 'edit') {
                openMeetingEditor(context, ref, meeting: meeting, roomId: roomId);
              } else if (v == 'delete') {
                final ok = await confirm(context,
                    title: '이 모임을 삭제할까요?',
                    message: '출석 기록도 함께 사라집니다.',
                    ok: '삭제',
                    danger: true);
                if (ok) {
                  await Refs.meetings(roomId).doc(meetingId).delete();
                  if (context.mounted) context.go('/meetings');
                }
              }
            },
            itemBuilder: (c) => const [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoomBadge(roomId),
                const SizedBox(height: 10),
                Text(
                    DateFormat('yyyy년 M월 d일 (E) a h:mm', 'ko_KR')
                        .format(meeting.startAt),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand)),
                if (meeting.place.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  KV('장소', meeting.place),
                ],
                if (meeting.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(meeting.description,
                      style: const TextStyle(fontSize: 13.5, height: 1.6)),
                ],
              ],
            ),
          ),
          const SectionTitle('내 참석 여부'),
          SoftCard(
            child: Column(
              children: [
                Row(
                  children: [
                    for (final s in [
                      AttendStatus.present,
                      AttendStatus.online,
                      AttendStatus.absent
                    ]) ...[
                      Expanded(
                        child: _StatusButton(
                          status: s,
                          selected: mine == s,
                          onTap: () => _setStatus(context, ref, s, mine),
                        ),
                      ),
                      if (s != AttendStatus.absent) const SizedBox(width: 8),
                    ],
                  ],
                ),
                if (mine == AttendStatus.absent &&
                    '${att[uid]?['reason'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('사유: ${att[uid]!['reason']}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.inkMuted)),
                  ),
                ],
              ],
            ),
          ),
          SectionTitle('참석 현황',
              trailing: Text(
                  '${att.values.where((v) => v['status'] == 'present').length}명 참석',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.inkMuted))),
          SoftCard(
            child: Column(
              children: [
                for (final group in [
                  (AttendStatus.present, '✅ 참석'),
                  (AttendStatus.online, '💻 온라인'),
                  (AttendStatus.absent, '🥲 불참'),
                  (AttendStatus.none, '⬜ 미체크'),
                ])
                  _StatusGroup(
                    label: group.$2,
                    members: members.where((m) {
                      final s = attendFrom(att[m.uid]?['status'] as String?);
                      return s == group.$1;
                    }).toList(),
                    reasons: {
                      for (final e in att.entries)
                        e.key: '${e.value['reason'] ?? ''}'
                    },
                    showReason: group.$1 == AttendStatus.absent,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => context.go('/more/albums'),
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: const Text('이 모임 사진 앨범으로'),
          ),
        ],
      ),
    );
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref,
      AttendStatus s, AttendStatus current) async {
    final uid = ref.read(myUidProvider);
    if (uid == null) return;

    String reason = '';
    if (s == AttendStatus.absent) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('불참 사유', style: TextStyle(fontSize: 17)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: '예: 알바, 가족 행사 (선택)'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('취소')),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('체크')),
          ],
        ),
      );
      if (ok != true) return;
      reason = ctrl.text.trim();
    }

    await Refs.attendance(roomId, meetingId).doc(uid).set({
      'uid': uid,
      'status': current == s ? 'none' : s.name,
      'reason': reason,
      'checkedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _StatusButton extends StatelessWidget {
  final AttendStatus status;
  final bool selected;
  final VoidCallback onTap;
  const _StatusButton(
      {required this.status, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (emoji, color) = switch (status) {
      AttendStatus.present => ('✅', AppColors.brand),
      AttendStatus.online => ('💻', AppColors.violet),
      AttendStatus.absent => ('🥲', AppColors.inkFaint),
      AttendStatus.none => ('⬜', AppColors.inkMuted),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AppColors.fill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? color : AppColors.line,
              width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(attendLabel(status),
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : AppColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _StatusGroup extends StatelessWidget {
  final String label;
  final List<Member> members;
  final Map<String, String> reasons;
  final bool showReason;
  const _StatusGroup({
    required this.label,
    required this.members,
    required this.reasons,
    this.showReason = false,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ${members.length}',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in members)
                Pill(showReason && (reasons[m.uid] ?? '').isNotEmpty
                    ? '${m.display} · ${reasons[m.uid]}'
                    : m.display),
            ],
          ),
        ],
      ),
    );
  }
}
