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

class SermonNotesPage extends ConsumerStatefulWidget {
  const SermonNotesPage({super.key});
  @override
  ConsumerState<SermonNotesPage> createState() => _SermonNotesPageState();
}

class _SermonNotesPageState extends ConsumerState<SermonNotesPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final roomId = ref.watch(currentRoomIdProvider);
    final async = ref.watch(currentSermonNotesProvider);
    final members = ref.watch(memberMapProvider);

    return SubPage(
      title: '말씀 노트',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: Center(child: RoomSwitchChip(compact: true)),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => openSheet(context, _NoteEditor(roomId: roomId)),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('노트 쓰기'),
      ),
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorNote(e),
        data: (all) {
          final q = _query.trim().toLowerCase();
          final list = q.isEmpty
              ? all
              : all
                  .where((n) =>
                      n.title.toLowerCase().contains(q) ||
                      n.scripture.toLowerCase().contains(q) ||
                      n.summary.toLowerCase().contains(q) ||
                      n.reflection.toLowerCase().contains(q) ||
                      n.tags.any((t) => t.toLowerCase().contains(q)))
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: '제목 · 본문 · 태그로 검색 (예: 예레미야)',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? EmptyState(
                        emoji: '📖',
                        title: q.isEmpty ? '아직 노트가 없어요' : '검색 결과가 없어요',
                        subtitle: q.isEmpty
                            ? '주일·수요예배 설교 요약과 묵상을 남겨보세요.\n태그를 달면 나중에 찾기 쉬워요.'
                            : null,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: list.length,
                        separatorBuilder: (a, b) => const SizedBox(height: 12),
                        itemBuilder: (c, i) => _NoteCard(
                          note: list[i],
                          roomId: roomId,
                          author: members[list[i].authorUid],
                          onTagTap: (t) => setState(() => _query = t),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final SermonNote note;
  final String roomId;
  final Member? author;
  final void Function(String) onTagTap;
  const _NoteCard({
    required this.note,
    required this.roomId,
    this.author,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(myUidProvider);
    return SoftCard(
      onTap: () => openSheet(context, _NoteDetail(note: note, author: author)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(DateFormat('yyyy.M.d').format(note.date)),
              const Spacer(),
              Avatar(member: author, size: 22),
              const SizedBox(width: 6),
              Text(author?.display ?? '',
                  style:
                      const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              if (note.authorUid == uid)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: 18, color: AppColors.muted),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      openSheet(context, _NoteEditor(note: note, roomId: roomId));
                    } else if (v == 'delete') {
                      final ok = await confirm(context,
                          title: '노트를 삭제할까요?', ok: '삭제', danger: true);
                      if (ok) await Refs.sermonNotes(roomId).doc(note.id).delete();
                    }
                  },
                  itemBuilder: (c) => const [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(note.title,
              style:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          if (note.scripture.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(note.scripture,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.deep,
                    fontWeight: FontWeight.w600)),
          ],
          if (note.summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, height: 1.65)),
          ],
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in note.tags)
                  GestureDetector(
                      onTap: () => onTagTap(t), child: Pill('#$t')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteDetail extends StatelessWidget {
  final SermonNote note;
  final Member? author;
  const _NoteDetail({required this.note, this.author});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHandle(note.title),
          Row(children: [
            Pill(DateFormat('yyyy.M.d').format(note.date)),
            const SizedBox(width: 8),
            Avatar(member: author, size: 22),
            const SizedBox(width: 6),
            Text(author?.display ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
          if (note.scripture.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(note.scripture,
                  style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.7,
                      color: AppColors.deep,
                      fontWeight: FontWeight.w600)),
            ),
          ],
          if (note.summary.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _NoteHead('설교 요약'),
            SelectableText(note.summary,
                style: const TextStyle(fontSize: 14, height: 1.75)),
          ],
          if (note.reflection.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _NoteHead('내 묵상'),
            SelectableText(note.reflection,
                style: const TextStyle(fontSize: 14, height: 1.75)),
          ],
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final t in note.tags) Pill('#$t')],
            ),
          ],
          const SizedBox(height: 10),
        ],
      );
}

class _NoteHead extends StatelessWidget {
  final String text;
  const _NoteHead(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.muted)),
      );
}

class _NoteEditor extends ConsumerStatefulWidget {
  final SermonNote? note;
  final String roomId;
  const _NoteEditor({this.note, required this.roomId});
  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _scripture =
      TextEditingController(text: widget.note?.scripture ?? '');
  late final _summary = TextEditingController(text: widget.note?.summary ?? '');
  late final _reflection =
      TextEditingController(text: widget.note?.reflection ?? '');
  late final _tags =
      TextEditingController(text: widget.note?.tags.join(', ') ?? '');
  late DateTime _date = widget.note?.date ?? DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _scripture.dispose();
    _summary.dispose();
    _reflection.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      toast(context, '제목을 입력해주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = ref.read(myUidProvider)!;
      final data = {
        'title': _title.text.trim(),
        'scripture': _scripture.text.trim(),
        'summary': _summary.text.trim(),
        'reflection': _reflection.text.trim(),
        'date': Timestamp.fromDate(_date),
        'tags': _tags.text
            .split(RegExp(r'[,\s]+'))
            .map((t) => t.replaceAll('#', '').trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'authorUid': widget.note?.authorUid ?? uid,
      };
      if (widget.note == null) {
        await Refs.sermonNotes(widget.roomId)
            .add({...data, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await Refs.sermonNotes(widget.roomId).doc(widget.note!.id).update(data);
      }
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
          SheetHandle(widget.note == null ? '말씀 노트' : '노트 수정',
              trailing: RoomBadge(widget.roomId)),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: '제목', hintText: '예: 절망에서 소망으로'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2026),
                lastDate: DateTime(2032),
                locale: const Locale('ko'),
              );
              if (d != null) setState(() => _date = d);
            },
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: '예배 날짜'),
              child: Text(DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_date),
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scripture,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '본문 말씀',
              hintText: '예: 예레미야 29:11 — 너희를 향한 나의 생각을 내가 아나니…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _summary,
            minLines: 4,
            maxLines: 12,
            decoration: const InputDecoration(
                labelText: '설교 요약', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reflection,
            minLines: 3,
            maxLines: 10,
            decoration: const InputDecoration(
                labelText: '내 묵상 (선택)', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(
                labelText: '태그 (선택)', hintText: '예레미야29:11, 소망, 수련회'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? '저장 중...' : '저장하기'),
          ),
        ],
      );
}
