import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_config.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/header_actions.dart';
import '../../widgets/room_switch.dart';

class MeetingsPage extends ConsumerWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(currentRoomIdProvider);
    final async = ref.watch(currentMeetingsProvider);
    final isLeader = ref.watch(isLeaderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('모임'),
        actions: [
          if (isLeader)
            IconButton(
              tooltip: '출석 통계',
              icon: const AppIcon(AppIcons.chart),
              onPressed: () =>
                  openSheet(context, _AttendanceStats(roomId: roomId)),
            ),
          const Center(child: RoomSwitchChip(compact: true)),
          const SizedBox(width: 4),
          const HeaderActions(),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openMeetingEditor(context, ref),
        icon: const AppIcon(AppIcons.plus),
        label: const Text('일정 등록'),
      ),
      body: SafeArea(
        child: Bounded(
          child: async.when(
            loading: () => const ListSkeleton(),
            error: (e, _) => ErrorNote(e),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: AppIcons.calendar,
                  title:
                      '${AppConfig.roomOf(roomId).name}에 등록된 모임이 없어요',
                  subtitle: '주일 사랑방, 아웃팅, 수련회 일정을 등록해보세요.\n'
                      '등록할 때 어느 사랑방 모임인지 고를 수 있어요.',
                );
              }
              final upcoming = list.where((m) => m.isUpcoming).toList()
                ..sort((a, b) => a.startAt.compareTo(b.startAt));
              final past = list.where((m) => !m.isUpcoming).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  if (upcoming.isNotEmpty) ...[
                    const SectionTitle('다가오는 일정'),
                    for (final m in upcoming) ...[
                      _MeetingTile(meeting: m, roomId: roomId),
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (past.isNotEmpty) ...[
                    const SectionTitle('지난 일정'),
                    for (final m in past) ...[
                      _MeetingTile(meeting: m, roomId: roomId, dim: true),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MeetingTile extends ConsumerWidget {
  final Meeting meeting;
  final String roomId;
  final bool dim;
  const _MeetingTile(
      {required this.meeting, required this.roomId, this.dim = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final att =
        ref.watch(attendanceProvider((roomId, meeting.id))).value ?? const {};
    final present = att.values.where((v) => v['status'] == 'present').length;
    final online = att.values.where((v) => v['status'] == 'online').length;
    final uid = ref.watch(myUidProvider);
    final mine = attendFrom(att[uid]?['status'] as String?);

    final (bg, fg) = switch (mine) {
      AttendStatus.present => (AppColors.brand50, AppColors.brand),
      AttendStatus.online => (AppColors.violetBg, AppColors.violet),
      AttendStatus.absent => (AppColors.fill, AppColors.inkMuted),
      AttendStatus.none => (AppColors.fill, AppColors.inkMuted),
    };

    return SoftCard(
      onTap: () => context.go('/meetings/$roomId/${meeting.id}'),
      child: Opacity(
        opacity: dim ? 0.7 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 블록 — 애기애타 일정 목록처럼 브랜드색으로 채움 (지난 일정은 회색)
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: dim ? AppColors.fill : AppColors.brand,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  Text(DateFormat('E', 'ko_KR').format(meeting.startAt),
                      style: AppText.micro.copyWith(
                          color: dim
                              ? AppColors.inkFaint
                              : Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 1),
                  Text('${meeting.startAt.day}',
                      style: AppText.num.copyWith(
                          fontSize: 20,
                          color: dim ? AppColors.inkMuted : Colors.white)),
                  Text('${meeting.startAt.month}월',
                      style: AppText.micro.copyWith(
                          color: dim
                              ? AppColors.inkFaint
                              : Colors.white.withValues(alpha: 0.9))),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(meeting.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.cardTitle),
                      ),
                      if (mine != AttendStatus.none)
                        Pill(attendLabel(mine), bg: bg, fg: fg),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const AppIcon(AppIcons.clock,
                          size: 12.5, color: AppColors.inkFaint),
                      const SizedBox(width: 4),
                      Text(DateFormat('a h:mm', 'ko_KR').format(meeting.startAt),
                          style: AppText.caption),
                      if (meeting.place.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        const AppIcon(AppIcons.pin,
                            size: 12.5, color: AppColors.inkFaint),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(meeting.place,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const AppIcon(AppIcons.users,
                          size: 13, color: AppColors.inkFaint),
                      const SizedBox(width: 4),
                      Text(
                          present + online == 0
                              ? '아직 체크한 사람이 없어요'
                              : '참석 $present명${online > 0 ? ' · 온라인 $online명' : ''}',
                          style: AppText.micro),
                      const Spacer(),
                      const AppIcon(AppIcons.chevronRight,
                          size: 18, color: AppColors.inkFaint),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 일정 등록/수정
Future<void> openMeetingEditor(
  BuildContext context,
  WidgetRef ref, {
  Meeting? meeting,
  String? roomId,
}) async {
  await openSheet(
    context,
    _MeetingEditor(
      meeting: meeting,
      initialRoomId: roomId ?? ref.read(currentRoomIdProvider),
    ),
  );
}

class _MeetingEditor extends ConsumerStatefulWidget {
  final Meeting? meeting;
  final String initialRoomId;
  const _MeetingEditor({this.meeting, required this.initialRoomId});
  @override
  ConsumerState<_MeetingEditor> createState() => _MeetingEditorState();
}

class _MeetingEditorState extends ConsumerState<_MeetingEditor> {
  late final _title = TextEditingController(text: widget.meeting?.title ?? '');
  late final _place = TextEditingController(text: widget.meeting?.place ?? '');
  late final _desc =
      TextEditingController(text: widget.meeting?.description ?? '');
  late DateTime _date = widget.meeting?.startAt ?? _defaultSunday();
  late String _roomId = widget.initialRoomId;
  bool _busy = false;

  static DateTime _defaultSunday() {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day, 15, 0);
    while (d.weekday != DateTime.sunday) {
      d = DateTime(d.year, d.month, d.day + 1, 15, 0);
    }
    return d;
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2026),
      lastDate: DateTime(2032),
      locale: const Locale('ko'),
    );
    if (d == null || !mounted) return;
    if (!context.mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    setState(() => _date = DateTime(d.year, d.month, d.day,
        t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      toast(context, '모임 이름을 입력해주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = ref.read(myUidProvider)!;
      final data = {
        'title': _title.text.trim(),
        'place': _place.text.trim(),
        'description': _desc.text.trim(),
        'startAt': Timestamp.fromDate(_date),
        'authorUid': widget.meeting?.authorUid ?? uid,
      };
      if (widget.meeting == null) {
        await Refs.meetings(_roomId)
            .add({...data, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        // 사랑방을 옮긴 경우: 새 방에 만들고 원래 방에서 지웁니다
        if (_roomId != widget.initialRoomId) {
          await Refs.meetings(_roomId)
              .add({...data, 'createdAt': FieldValue.serverTimestamp()});
          await Refs.meetings(widget.initialRoomId)
              .doc(widget.meeting!.id)
              .delete();
        } else {
          await Refs.meetings(_roomId)
              .doc(widget.meeting!.id)
              .set(data, SetOptions(merge: true));
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myRooms = ref.watch(myRoomsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHandle(widget.meeting == null ? '모임 등록' : '모임 수정'),

        // 어느 사랑방 모임인지
        Text('어느 사랑방 모임인가요?', style: AppText.label),
        const SizedBox(height: 9),
        Row(
          children: [
            for (final r in myRooms) ...[
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _roomId = r.id),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _roomId == r.id
                          ? AppColors.brand50
                          : AppColors.fill,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: _roomId == r.id
                            ? AppColors.brand
                            : Colors.transparent,
                        width: 1.6,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(r.name,
                            style: AppText.label.copyWith(
                              fontSize: 12.5,
                              color: _roomId == r.id
                                  ? AppColors.brand
                                  : AppColors.inkMuted,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              if (r != myRooms.last) const SizedBox(width: 8),
            ],
          ],
        ),

        const SizedBox(height: 18),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
              labelText: '모임 이름', hintText: '예: 8월 마지막 주 사랑방'),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            decoration: const InputDecoration(labelText: '날짜 / 시간'),
            child: Text(
                DateFormat('yyyy년 M월 d일 (E) a h:mm', 'ko_KR').format(_date),
                style: const TextStyle(fontSize: 14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _place,
          decoration:
              const InputDecoration(labelText: '장소', hintText: '예: 201호 → 108호'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _desc,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
              labelText: '안내 (선택)', hintText: '준비물, 모이는 방법 등'),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '저장 중...' : '저장하기'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────── 출석 통계 (방장 전용)
class _AttendanceStats extends ConsumerStatefulWidget {
  final String roomId;
  const _AttendanceStats({required this.roomId});
  @override
  ConsumerState<_AttendanceStats> createState() => _AttendanceStatsState();
}

class _AttendanceStatsState extends ConsumerState<_AttendanceStats> {
  Map<String, ({int present, int total})>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final meetings = await ref.read(meetingsProvider(widget.roomId).future);
      final past = meetings.where((m) => !m.isUpcoming).toList();
      final acc = <String, ({int present, int total})>{};
      for (final m in past) {
        final snap = await Refs.attendance(widget.roomId, m.id).get();
        for (final d in snap.docs) {
          final s = d.data()['status'];
          final cur = acc[d.id] ?? (present: 0, total: 0);
          acc[d.id] = (
            present: cur.present + (s == 'present' || s == 'online' ? 1 : 0),
            total: cur.total + 1,
          );
        }
      }
      if (mounted) setState(() => _result = acc);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(roomMembersProvider(widget.roomId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHandle('${AppConfig.roomOf(widget.roomId).name} 출석 통계',
            trailing: const Pill('방장 전용', icon: AppIcons.lock)),
        if (_error != null)
          Text(_error!, style: AppText.caption.copyWith(color: AppColors.danger))
        else if (_result == null)
          const Loading()
        else if (_result!.isEmpty)
          const EmptyState(icon: AppIcons.chart, title: '아직 집계할 지난 모임이 없어요')
        else
          for (final m in members)
            Builder(builder: (_) {
              final r = _result![m.uid];
              final rate =
                  (r == null || r.total == 0) ? 0.0 : r.present / r.total;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Avatar(member: m, size: 28),
                    const SizedBox(width: 10),
                    SizedBox(
                        width: 74,
                        child: Text(m.display,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label.copyWith(fontSize: 13))),
                    Expanded(child: Meter(rate)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 66,
                      child: Text(
                        r == null
                            ? '기록 없음'
                            : '${(rate * 100).round()}% (${r.present}/${r.total})',
                        textAlign: TextAlign.right,
                        style: AppText.micro,
                      ),
                    ),
                  ],
                ),
              );
            }),
        const SizedBox(height: 10),
        Text('지난 모임에서 본인이 체크한 기록만 집계됩니다.',
            textAlign: TextAlign.center, style: AppText.micro),
      ],
    );
  }
}
