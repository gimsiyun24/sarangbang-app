import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../core/week.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

Future<void> openPrayerEditor(
  BuildContext context,
  WidgetRef ref, {
  required Week week,
}) async {
  final uid = ref.read(myUidProvider);
  final roomId = ref.read(myRoomIdProvider);
  if (uid == null || roomId.isEmpty) return;
  final existing = ref.read(myPrayerProvider(week.id));

  await openSheet(
    context,
    _PrayerEditor(week: week, uid: uid, roomId: roomId, existing: existing),
  );
}

class _PrayerEditor extends ConsumerStatefulWidget {
  final Week week;
  final String uid, roomId;
  final PrayerEntry? existing;
  const _PrayerEditor({
    required this.week,
    required this.uid,
    required this.roomId,
    this.existing,
  });

  @override
  ConsumerState<_PrayerEditor> createState() => _PrayerEditorState();
}

class _Row {
  final TextEditingController ctrl;
  Vis vis;
  List<String> prayedBy;
  _Row(String text, this.vis, {this.prayedBy = const []})
      : ctrl = TextEditingController(text: text);
}

class _PrayerEditorState extends ConsumerState<_PrayerEditor> {
  late List<_Row> _topics;
  late List<TextEditingController> _routines;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _topics = [
      ...?e?.topics.map((t) => _Row(t.text, t.visibility, prayedBy: t.prayedBy)),
      ...?e?.private
          .map((t) => _Row(t.text, Vis.private, prayedBy: t.prayedBy)),
    ];
    if (_topics.isEmpty) _topics = [_Row('', Vis.all)];

    _routines = [
      ...?e?.routines.map((r) => TextEditingController(text: r)),
    ];
    if (_routines.isEmpty) _routines = [TextEditingController()];
  }

  @override
  void dispose() {
    for (final t in _topics) {
      t.ctrl.dispose();
    }
    for (final r in _routines) {
      r.dispose();
    }
    super.dispose();
  }

  PrayerTopic _toTopic(_Row r) => PrayerTopic(
        text: r.ctrl.text.trim(),
        visibility: r.vis,
        prayedBy: r.prayedBy,
      );

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final all = _topics
          .map(_toTopic)
          .where((t) => t.text.isNotEmpty)
          .toList();
      final publicTopics = all.where((t) => !t.isPrivate).toList();
      final privateTopics = all.where((t) => t.isPrivate).toList();
      final routines = _routines
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final batch = Refs.db.batch();

      // 주차 문서가 없으면 만들어 둡니다
      batch.set(
        Refs.week(widget.roomId, widget.week.id),
        {
          'startDate': Timestamp.fromDate(widget.week.sunday),
          'endDate': Timestamp.fromDate(widget.week.saturday),
          'closed': false,
        },
        SetOptions(merge: true),
      );

      batch.set(Refs.prayer(widget.roomId, widget.week.id, widget.uid), {
        'uid': widget.uid,
        'visibility': 'all', // 문서 자체는 목록에 뜨도록 공개
        'topics': publicTopics.map((t) => t.toMap()).toList(),
        'routines': routines,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.set(Refs.prayerPrivate(widget.roomId, widget.week.id, widget.uid), {
        'uid': widget.uid,
        'topics': privateTopics.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      if (mounted) {
        Navigator.pop(context);
        toast(context, '저장했어요 🙏');
      }
    } catch (e) {
      if (mounted) toast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHandle('${widget.week.mmdd} 내 기도제목',
            trailing: Text(widget.week.range,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted))),

        const _Head('기도제목'),
        for (var i = 0; i < _topics.length; i++) _topicRow(i),
        _AddButton(
          label: '기도제목 추가',
          onTap: () => setState(() => _topics.add(_Row('', Vis.all))),
        ),

        const SizedBox(height: 22),
        const _Head('신앙루틴'),
        for (var i = 0; i < _routines.length; i++) _routineRow(i),
        _AddButton(
          label: '루틴 추가',
          onTap: () => setState(() => _routines.add(TextEditingController())),
        ),

        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '저장 중...' : '저장하기'),
        ),
        const SizedBox(height: 10),
        const Text(
          '🔒 나만 보기로 둔 항목은 카톡 복사에도 들어가지 않고,\n보안 규칙에서 본인 외 아무도 읽을 수 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.6),
        ),
      ],
    );
  }

  Widget _topicRow(int i) {
    final r = _topics[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: r.ctrl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '예: 이번 학기 잘 마칠 수 있도록',
                    suffixIcon: _topics.length > 1
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() {
                              _topics.removeAt(i).ctrl.dispose();
                            }),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _VisChip(
                selected: r.vis == Vis.all,
                icon: Icons.groups_rounded,
                label: '전체 공개',
                onTap: () => setState(() => r.vis = Vis.all),
              ),
              const SizedBox(width: 6),
              _VisChip(
                selected: r.vis == Vis.private,
                icon: Icons.lock_rounded,
                label: '나만 보기',
                onTap: () => setState(() => r.vis = Vis.private),
              ),
              const Spacer(),
              if (r.prayedBy.isNotEmpty)
                Text('🙏 ${r.prayedBy.length}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routineRow(int i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: _routines[i],
          decoration: InputDecoration(
            hintText: '예: 매일 감사기도 드리기',
            suffixIcon: _routines.length > 1
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () =>
                        setState(() => _routines.removeAt(i).dispose()),
                  )
                : null,
          ),
        ),
      );
}

class _Head extends StatelessWidget {
  final String text;
  const _Head(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.deep)),
      );
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      );
}

class _VisChip extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _VisChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.deep : const Color(0xFFF1F5F3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 13,
                  color: selected ? Colors.white : AppColors.muted),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.muted)),
            ],
          ),
        ),
      );
}
