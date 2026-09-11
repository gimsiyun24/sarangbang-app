import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/push.dart';
import '../../core/refs.dart';
import '../../models/models.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/room_switch.dart';

class PollsPage extends ConsumerWidget {
  const PollsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(currentRoomIdProvider);
    final async = ref.watch(currentPollsProvider);

    return SubPage(
      title: '투표 / 일정 조율',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: Center(child: RoomSwitchChip(compact: true)),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => openSheet(context, _PollEditor(roomId: roomId)),
        icon: const AppIcon(AppIcons.voteStamp),
        label: const Text('투표 만들기'),
      ),
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorNote(e),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: AppIcons.voteStamp,
              title: '아직 투표가 없어요',
              subtitle: '아웃팅 장소·날짜를 정할 때 써보세요.\n카톡 투표와 달리 결과가 영구 보존됩니다.',
            );
          }
          final open = list.where((p) => !p.isOver).toList();
          final done = list.where((p) => p.isOver).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              if (open.isNotEmpty) ...[
                const SectionTitle('진행 중'),
                for (final p in open) ...[
                  _PollCard(poll: p, roomId: roomId),
                  const SizedBox(height: 12)
                ],
              ],
              if (done.isNotEmpty) ...[
                const SectionTitle('종료된 투표'),
                for (final p in done) ...[
                  _PollCard(poll: p, roomId: roomId),
                  const SizedBox(height: 12)
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PollCard extends ConsumerWidget {
  final Poll poll;
  final String roomId;
  const _PollCard({required this.poll, required this.roomId});

  Future<void> _vote(WidgetRef ref, PollOption opt) async {
    final uid = ref.read(myUidProvider);
    if (uid == null || poll.isOver) return;

    final options = poll.options.map((o) {
      var votes = [...o.votes];
      if (o.id == opt.id) {
        votes.contains(uid) ? votes.remove(uid) : votes.add(uid);
      } else if (!poll.multi) {
        votes.remove(uid);
      }
      return PollOption(id: o.id, label: o.label, votes: votes).toMap();
    }).toList();

    await Refs.polls(roomId).doc(poll.id).update({'options': options});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(myUidProvider);
    final members = ref.watch(memberMapProvider);
    final maxVotes =
        poll.options.fold<int>(0, (m, o) => o.votes.length > m ? o.votes.length : m);

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(poll.isOver ? '종료' : '진행 중',
                  bg: poll.isOver ? AppColors.fill : AppColors.brand50,
                  fg: poll.isOver ? AppColors.inkMuted : AppColors.brand),
              if (poll.multi) ...[
                const SizedBox(width: 6),
                const Pill('복수 선택'),
              ],
              const Spacer(),
              if (poll.authorUid == uid)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: AppIcon(AppIcons.moreHoriz,
                      size: 18, color: AppColors.inkMuted),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) async {
                    if (v == 'close') {
                      await Refs.polls(roomId)
                          .doc(poll.id)
                          .update({'closed': !poll.closed});
                    } else if (v == 'delete') {
                      final ok = await confirm(context,
                          title: '투표를 삭제할까요?', ok: '삭제', danger: true);
                      if (ok) await Refs.polls(roomId).doc(poll.id).delete();
                    }
                  },
                  itemBuilder: (c) => [
                    PopupMenuItem(
                        value: 'close',
                        child: Text(poll.closed ? '다시 열기' : '지금 종료')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(poll.question,
              style:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          if (poll.closesAt != null) ...[
            const SizedBox(height: 4),
            Text(
                '마감 ${DateFormat('M/d (E) a h:mm', 'ko_KR').format(poll.closesAt!)}',
                style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
          ],
          const SizedBox(height: 14),
          for (final o in poll.options) ...[
            _OptionBar(
              option: o,
              mine: uid != null && o.votes.contains(uid),
              max: maxVotes,
              isOver: poll.isOver,
              members: members,
              onTap: () => _vote(ref, o),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Text('${poll.voters.length}명 참여',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.inkMuted)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => copyToClipboard(
                  context,
                  _resultText(poll, members),
                  message: '결과를 복사했어요',
                ),
                icon: const AppIcon(AppIcons.copy, size: 15),
                label: const Text('결과 복사', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _resultText(Poll p, Map<String, Member> members) {
    final b = StringBuffer()..writeln('🗳️ ${p.question}')..writeln();
    for (final o in p.options) {
      b.writeln('· ${o.label} — ${o.votes.length}표'
          '${o.votes.isEmpty ? '' : ' (${o.votes.map((u) => members[u]?.shortName ?? '?').join(', ')})'}');
    }
    b.writeln();
    b.write('총 ${p.voters.length}명 참여');
    return b.toString();
  }
}

class _OptionBar extends StatelessWidget {
  final PollOption option;
  final bool mine, isOver;
  final int max;
  final Map<String, Member> members;
  final VoidCallback onTap;

  const _OptionBar({
    required this.option,
    required this.mine,
    required this.max,
    required this.isOver,
    required this.members,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : option.votes.length / max;
    return InkWell(
      onTap: isOver ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          FractionallySizedBox(
            widthFactor: ratio.clamp(0.0, 1.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              height: 46,
              decoration: BoxDecoration(
                color: mine
                    ? AppColors.brand.withValues(alpha: 0.28)
                    : AppColors.brand50,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  AppIcon(
                    mine ? AppIcons.checkCircle : AppIcons.circle,
                    size: 17,
                    color: mine ? AppColors.brand : AppColors.lineStrong,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(option.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: mine ? FontWeight.w800 : FontWeight.w600)),
                  ),
                  if (option.votes.isNotEmpty) ...[
                    Text(
                      option.votes
                          .map((u) => members[u]?.shortName ?? '?')
                          .take(3)
                          .join(','),
                      style: TextStyle(
                          fontSize: 10.5, color: AppColors.inkMuted),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text('${option.votes.length}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── 투표 만들기
class _PollEditor extends ConsumerStatefulWidget {
  final String roomId;
  const _PollEditor({required this.roomId});
  @override
  ConsumerState<_PollEditor> createState() => _PollEditorState();
}

class _PollEditorState extends ConsumerState<_PollEditor> {
  final _question = TextEditingController();
  final _options = [TextEditingController(), TextEditingController()];
  DateTime? _closesAt;
  bool _multi = false, _busy = false;

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final opts = _options
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (_question.text.trim().isEmpty || opts.length < 2) {
      toast(context, '질문과 선택지 2개 이상을 입력해주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = ref.read(myUidProvider)!;
      final doc = await Refs.polls(widget.roomId).add({
        'question': _question.text.trim(),
        'options': [
          for (var i = 0; i < opts.length; i++)
            {'id': 'o$i', 'label': opts[i], 'votes': <String>[]}
        ],
        'multi': _multi,
        'closed': false,
        'closesAt': _closesAt == null ? null : Timestamp.fromDate(_closesAt!),
        'authorUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      requestPush(PushKind.poll, roomId: widget.roomId, id: doc.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHandle('투표 만들기', trailing: RoomBadge(widget.roomId)),
          TextField(
            controller: _question,
            decoration: const InputDecoration(
                labelText: '질문', hintText: '예: 2월 아웃팅 어디로 갈까요?'),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _options[i],
                decoration: InputDecoration(
                  hintText: '선택지 ${i + 1}',
                  suffixIcon: _options.length > 2
                      ? IconButton(
                          icon: const AppIcon(AppIcons.close, size: 18),
                          onPressed: () =>
                              setState(() => _options.removeAt(i).dispose()),
                        )
                      : null,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _options.add(TextEditingController())),
              icon: const AppIcon(AppIcons.plus, size: 18),
              label: const Text('선택지 추가', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _multi,
            onChanged: (v) => setState(() => _multi = v),
            title: const Text('복수 선택 허용', style: TextStyle(fontSize: 13.5)),
          ),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 3)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2032),
                locale: const Locale('ko'),
              );
              if (d == null || !context.mounted) return;
              final t = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 23, minute: 59),
              );
              setState(() => _closesAt = DateTime(
                  d.year, d.month, d.day, t?.hour ?? 23, t?.minute ?? 59));
            },
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: '마감 시각 (선택)'),
              child: Text(
                _closesAt == null
                    ? '설정 안 함'
                    : DateFormat('M월 d일 (E) a h:mm', 'ko_KR').format(_closesAt!),
                style: TextStyle(
                    fontSize: 14,
                    color: _closesAt == null ? AppColors.inkMuted : null),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? '만드는 중...' : '투표 시작'),
          ),
        ],
      );
}
