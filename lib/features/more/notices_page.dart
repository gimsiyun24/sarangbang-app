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

class NoticesPage extends ConsumerWidget {
  const NoticesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(currentRoomIdProvider);
    final async = ref.watch(currentNoticesProvider);

    return SubPage(
      title: '공지 게시판',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: Center(child: RoomSwitchChip(compact: true)),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => openSheet(context, _NoticeEditor(roomId: roomId)),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('공지 쓰기'),
      ),
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorNote(e),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              emoji: '📢',
              title: '아직 공지가 없어요',
              subtitle: '수련회·MT·아웃팅 공지를 여기에 올리면\n잡담에 묻히지 않습니다.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: list.length,
            separatorBuilder: (a, b) => const SizedBox(height: 12),
            itemBuilder: (c, i) => _NoticeCard(notice: list[i], roomId: roomId),
          );
        },
      ),
    );
  }
}

class _NoticeCard extends ConsumerStatefulWidget {
  final Notice notice;
  final String roomId;
  const _NoticeCard({required this.notice, required this.roomId});
  @override
  ConsumerState<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends ConsumerState<_NoticeCard> {
  bool _expanded = false;

  Future<void> _markRead() async {
    final uid = ref.read(myUidProvider);
    if (uid == null || widget.notice.readBy.contains(uid)) return;
    await Refs.notices(widget.roomId).doc(widget.notice.id).update({
      'readBy': FieldValue.arrayUnion([uid])
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notice;
    final uid = ref.watch(myUidProvider);
    final members = ref.watch(roomMembersProvider(widget.roomId));
    final map = ref.watch(memberMapProvider);
    final unreadMembers =
        members.where((m) => !n.readBy.contains(m.uid)).toList();

    return SoftCard(
      onTap: () {
        setState(() => _expanded = !_expanded);
        _markRead();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (n.pinned) ...[
                const Text('📌', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(n.title,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
              ),
              if (n.authorUid == uid)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz_rounded,
                      size: 18, color: AppColors.inkMuted),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) async {
                    if (v == 'pin') {
                      await Refs.notices(widget.roomId)
                          .doc(n.id)
                          .update({'pinned': !n.pinned});
                    } else if (v == 'edit') {
                      if (context.mounted) {
                        openSheet(context,
                            _NoticeEditor(notice: n, roomId: widget.roomId));
                      }
                    } else if (v == 'delete') {
                      final ok = await confirm(context,
                          title: '공지를 삭제할까요?', ok: '삭제', danger: true);
                      if (ok) await Refs.notices(widget.roomId).doc(n.id).delete();
                    }
                  },
                  itemBuilder: (c) => [
                    PopupMenuItem(
                        value: 'pin',
                        child: Text(n.pinned ? '고정 해제' : '상단 고정')),
                    const PopupMenuItem(value: 'edit', child: Text('수정')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(map[n.authorUid]?.display ?? '',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.inkMuted)),
              if (n.createdAt != null) ...[
                const Text(' · ',
                    style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
                Text(DateFormat('M/d HH:mm').format(n.createdAt!),
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.inkMuted)),
              ],
              const Spacer(),
              Pill('읽음 ${n.readBy.length}/${members.length}',
                  bg: unreadMembers.isEmpty
                      ? AppColors.brand50
                      : AppColors.goldBg,
                  fg: unreadMembers.isEmpty
                      ? AppColors.brand
                      : AppColors.gold),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            n.body,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, height: 1.7),
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => copyToClipboard(
                        context, '${n.title}\n\n${n.body}'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('내용 복사', style: TextStyle(fontSize: 13)),
                  ),
                ),
                if (unreadMembers.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openSheet(
                        context,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SheetHandle('아직 안 읽은 사람'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final m in unreadMembers)
                                  Chip(
                                    avatar: Avatar(member: m, size: 22),
                                    label: Text(m.display),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      icon: const Icon(Icons.visibility_off_outlined, size: 16),
                      label: Text('안 읽음 ${unreadMembers.length}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NoticeEditor extends ConsumerStatefulWidget {
  final Notice? notice;
  final String roomId;
  const _NoticeEditor({this.notice, required this.roomId});
  @override
  ConsumerState<_NoticeEditor> createState() => _NoticeEditorState();
}

class _NoticeEditorState extends ConsumerState<_NoticeEditor> {
  late final _title = TextEditingController(text: widget.notice?.title ?? '');
  late final _body = TextEditingController(text: widget.notice?.body ?? '');
  late bool _pinned = widget.notice?.pinned ?? false;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
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
      if (widget.notice == null) {
        await Refs.notices(widget.roomId).add({
          'title': _title.text.trim(),
          'body': _body.text.trim(),
          'authorUid': uid,
          'pinned': _pinned,
          'readBy': [uid],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await Refs.notices(widget.roomId).doc(widget.notice!.id).update({
          'title': _title.text.trim(),
          'body': _body.text.trim(),
          'pinned': _pinned,
        });
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
          SheetHandle(widget.notice == null ? '공지 쓰기' : '공지 수정',
              trailing: RoomBadge(widget.roomId)),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
                labelText: '제목', hintText: '예: 2026 여름 수련회 안내'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            minLines: 6,
            maxLines: 16,
            decoration: const InputDecoration(
              labelText: '내용',
              hintText: '주제 / 일정 / 장소 / 회비 / 신청 링크 …',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: _pinned,
            onChanged: (v) => setState(() => _pinned = v),
            title: const Text('상단에 고정', style: TextStyle(fontSize: 13.5)),
            subtitle: const Text('홈 화면에도 표시됩니다',
                style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? '저장 중...' : '올리기'),
          ),
        ],
      );
}
