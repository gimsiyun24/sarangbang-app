import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../models/models.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/room_switch.dart';

class SettlementsPage extends ConsumerWidget {
  const SettlementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(currentRoomIdProvider);
    final async = ref.watch(currentSettlementsProvider);

    return SubPage(
      title: '정산 내역',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: Center(child: RoomSwitchChip(compact: true)),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => openSheet(context, _SettlementEditor(roomId: roomId)),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('정산 만들기'),
      ),
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorNote(e),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              emoji: '🧾',
              title: '정산 내역이 없어요',
              subtitle: '볼링·식비·유류비·MT 회비를 1/N로 계산하고\n누가 입금했는지 체크할 수 있어요.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: list.length,
            separatorBuilder: (a, b) => const SizedBox(height: 12),
            itemBuilder: (c, i) => _SettlementCard(s: list[i], roomId: roomId),
          );
        },
      ),
    );
  }
}

class _SettlementCard extends ConsumerStatefulWidget {
  final Settlement s;
  final String roomId;
  const _SettlementCard({required this.s, required this.roomId});
  @override
  ConsumerState<_SettlementCard> createState() => _SettlementCardState();
}

class _SettlementCardState extends ConsumerState<_SettlementCard> {
  bool _open = false;

  Future<void> _togglePaid(String uid) async {
    final s = widget.s;
    await Refs.settlements(widget.roomId).doc(s.id).update({
      'paid': s.paid.contains(uid)
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final uid = ref.watch(myUidProvider);
    final members = ref.watch(memberMapProvider);
    final people = s.everyone;
    final unpaid = people.where((u) => !s.paid.contains(u)).toList();
    final myAmount = uid == null ? 0 : s.amountFor(uid);

    return SoftCard(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.title,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
              if (s.authorUid == uid)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: 18, color: AppColors.inkMuted),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) async {
                    if (v == 'delete') {
                      final ok = await confirm(context,
                          title: '정산을 삭제할까요?', ok: '삭제', danger: true);
                      if (ok) await Refs.settlements(widget.roomId).doc(s.id).delete();
                    }
                  },
                  itemBuilder: (c) => const [
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Stat('총액', won(s.totalAmount)),
              ),
              if (s.supportAmount > 0)
                Expanded(
                  child: _Stat('교회지원', '-${won(s.supportAmount)}',
                      color: AppColors.brand),
                ),
              Expanded(
                child: _Stat('1인당', won(s.shareBase), strong: true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: people.isEmpty ? 0 : s.paid.length / people.length,
              minHeight: 7,
              backgroundColor: AppColors.fill,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('입금 ${s.paid.length}/${people.length}명',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.inkMuted)),
              const Spacer(),
              if (uid != null && people.contains(uid))
                Pill(
                  s.paid.contains(uid) ? '내 입금 완료' : '내 몫 ${won(myAmount)}',
                  bg: s.paid.contains(uid)
                      ? AppColors.brand50
                      : AppColors.goldBg,
                  fg: s.paid.contains(uid)
                      ? AppColors.brand
                      : AppColors.gold,
                ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            if (s.account.isNotEmpty)
              InkWell(
                onTap: () => copyToClipboard(context, s.account,
                    message: '계좌번호를 복사했어요'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.account_balance_outlined,
                        size: 16, color: AppColors.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.account,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand)),
                    ),
                    const Icon(Icons.copy_rounded,
                        size: 15, color: AppColors.brand),
                  ]),
                ),
              ),
            if (s.deadline != null) ...[
              const SizedBox(height: 8),
              Text(
                  '입금 기한 ${DateFormat('M월 d일 (E)', 'ko_KR').format(s.deadline!)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.inkMuted)),
            ],
            if (s.memo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(s.memo,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.inkMuted, height: 1.6)),
            ],
            const SizedBox(height: 14),
            for (final u in people)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Avatar(member: members[u], size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(members[u]?.display ?? '이름없음',
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600)),
                          if (s.extraFor(u) > 0)
                            Text(
                                s.extraItems
                                    .where((e) => e.uid == u)
                                    .map((e) => '${e.label} ${won(e.amount)}')
                                    .join(', '),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.inkMuted)),
                        ],
                      ),
                    ),
                    Text(won(s.amountFor(u)),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _togglePaid(u),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: s.paid.contains(u)
                              ? AppColors.brand
                              : AppColors.fill,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(s.paid.contains(u) ? '입금완료' : '미입금',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: s.paid.contains(u)
                                    ? Colors.white
                                    : AppColors.inkMuted)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => copyToClipboard(
                        context, _text(s, members),
                        message: '정산 내역을 복사했어요'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('카톡용 복사',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                if (unpaid.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => copyToClipboard(
                        context,
                        '💸 ${s.title} 아직 입금 안 하신 분들이에요\n'
                        '${unpaid.map((u) => members[u]?.shortName ?? '?').join(', ')}\n'
                        '${s.account}',
                        message: '독촉(?) 문구를 복사했어요',
                      ),
                      icon: const Icon(Icons.campaign_outlined, size: 16),
                      label: Text('미입금 ${unpaid.length}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Text('⚠️ 앱이 돈을 옮기지 않습니다. 계좌 안내와 체크만 합니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.inkMuted)),
          ],
        ],
      ),
    );
  }

  static String _text(Settlement s, Map<String, Member> members) {
    final b = StringBuffer()..writeln('🧾 ${s.title}');
    b.writeln('총액 ${won(s.totalAmount)}');
    if (s.supportAmount > 0) b.writeln('교회지원 -${won(s.supportAmount)}');
    b.writeln('1인당 ${won(s.shareBase)} (${s.participants.length}명)');
    if (s.extraItems.isNotEmpty) {
      b.writeln();
      for (final e in s.extraItems) {
        b.writeln('· ${members[e.uid]?.shortName ?? '?'} ${e.label} +${won(e.amount)}');
      }
    }
    b.writeln();
    for (final u in s.everyone) {
      b.writeln(
          '${s.paid.contains(u) ? '✅' : '⬜'} ${members[u]?.shortName ?? '?'} ${won(s.amountFor(u))}');
    }
    if (s.account.isNotEmpty) {
      b..writeln()..writeln('입금 ${s.account}');
    }
    return b.toString().trimRight();
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final bool strong;
  final Color? color;
  const _Stat(this.label, this.value, {this.strong = false, this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: strong ? 15 : 13.5,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  color: color ?? (strong ? AppColors.brand : null))),
        ],
      );
}

// ─────────────────────────────────────────── 정산 만들기
class _SettlementEditor extends ConsumerStatefulWidget {
  final String roomId;
  const _SettlementEditor({required this.roomId});
  @override
  ConsumerState<_SettlementEditor> createState() => _SettlementEditorState();
}

class _SettlementEditorState extends ConsumerState<_SettlementEditor> {
  final _title = TextEditingController();
  final _total = TextEditingController();
  final _support = TextEditingController();
  final _account = TextEditingController();
  final _memo = TextEditingController();
  final _selected = <String>{};
  final _extras = <({String uid, TextEditingController label, TextEditingController amount})>[];
  DateTime? _deadline;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _total.dispose();
    _support.dispose();
    _account.dispose();
    _memo.dispose();
    for (final e in _extras) {
      e.label.dispose();
      e.amount.dispose();
    }
    super.dispose();
  }

  int get _totalV => int.tryParse(_total.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _supportV =>
      int.tryParse(_support.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get _share => _selected.isEmpty
      ? 0
      : ((((_totalV - _supportV).clamp(0, 1 << 40)) / _selected.length) / 10)
              .ceil() *
          10;

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _selected.isEmpty) {
      toast(context, '제목과 참여자를 입력해주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = ref.read(myUidProvider)!;
      await Refs.settlements(widget.roomId).add({
        'title': _title.text.trim(),
        'totalAmount': _totalV,
        'supportAmount': _supportV,
        'participants': _selected.toList(),
        'extraItems': [
          for (final e in _extras)
            if (e.label.text.trim().isNotEmpty)
              {
                'uid': e.uid,
                'label': e.label.text.trim(),
                'amount': int.tryParse(
                        e.amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                    0,
              }
        ],
        'paid': <String>[],
        'account': _account.text.trim(),
        'memo': _memo.text.trim(),
        'deadline': _deadline == null ? null : Timestamp.fromDate(_deadline!),
        'authorUid': uid,
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(roomMembersProvider(widget.roomId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHandle('정산 만들기', trailing: RoomBadge(widget.roomId)),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
              labelText: '항목', hintText: '예: 1월 볼링 + 저녁'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _total,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: '총액', suffixText: '원', hintText: '198000'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _support,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: '교회 지원금', suffixText: '원', hintText: '150000'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('참여자',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                if (_selected.length == members.length) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(members.map((m) => m.uid));
                }
              }),
              child: Text(
                  _selected.length == members.length ? '전체 해제' : '전체 선택',
                  style: const TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in members)
              FilterChip(
                selected: _selected.contains(m.uid),
                label: Text(m.display),
                showCheckmark: false,
                selectedColor: AppColors.brand,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _selected.contains(m.uid)
                      ? Colors.white
                      : AppColors.brand,
                ),
                onSelected: (v) => setState(() =>
                    v ? _selected.add(m.uid) : _selected.remove(m.uid)),
              ),
          ],
        ),
        if (_selected.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.brand50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('1인당',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand)),
                const Spacer(),
                Text('${won(_share)}  (${_selected.length}명)',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('개별 추가 (유류비 등)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: members.isEmpty
                  ? null
                  : () => setState(() => _extras.add((
                        uid: members.first.uid,
                        label: TextEditingController(),
                        amount: TextEditingController(),
                      ))),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('추가', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
        for (var i = 0; i < _extras.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: DropdownButtonFormField<String>(
                    initialValue: _extras[i].uid,
                    isDense: true,
                    items: [
                      for (final m in members)
                        DropdownMenuItem(
                            value: m.uid,
                            child: Text(m.display,
                                style: const TextStyle(fontSize: 12)))
                    ],
                    onChanged: (v) => setState(() {
                      if (v != null) {
                        _extras[i] = (
                          uid: v,
                          label: _extras[i].label,
                          amount: _extras[i].amount
                        );
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _extras[i].label,
                    decoration: const InputDecoration(
                        hintText: '유류비', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _extras[i].amount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        hintText: '10000', isDense: true, suffixText: '원'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() {
                    final e = _extras.removeAt(i);
                    e.label.dispose();
                    e.amount.dispose();
                  }),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _account,
          decoration: const InputDecoration(
              labelText: '입금 계좌', hintText: '예: 카카오뱅크 3333-01-1234567 이희진'),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2032),
              locale: const Locale('ko'),
            );
            if (d != null) setState(() => _deadline = d);
          },
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: const InputDecoration(labelText: '입금 기한 (선택)'),
            child: Text(
              _deadline == null
                  ? '설정 안 함'
                  : DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_deadline!),
              style: TextStyle(
                  fontSize: 14,
                  color: _deadline == null ? AppColors.inkMuted : null),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _memo,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
              labelText: '메모 (선택)', alignLabelWithHint: true),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '저장 중...' : '정산 만들기'),
        ),
      ],
    );
  }
}
