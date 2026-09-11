import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_config.dart';
import '../../core/cloudinary.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../models/models.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/room_switch.dart';

class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(currentRoomIdProvider);
    final async = ref.watch(currentAlbumsProvider);

    return SubPage(
      title: '앨범',
      actions: [
        if (!AppConfig.isCloudinaryConfigured)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(
                child: Pill('Cloudinary 미설정',
                    bg: AppColors.warnBg, fg: AppColors.warn)),
          ),
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Center(child: RoomSwitchChip(compact: true)),
        ),
      ],
      fab: FloatingActionButton.extended(
        onPressed: () => openAlbumEditor(context, ref),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('앨범 만들기'),
      ),
      body: async.when(
        loading: () => const ListSkeleton(count: 2),
        error: (e, _) => ErrorNote(e),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              emoji: '📸',
              title: '${AppConfig.roomOf(roomId).name}에 앨범이 없어요',
              subtitle: '모임·아웃팅·수련회별로 앨범을 만들어 두면\n'
                  '1년치 사진이 만료 없이 남습니다.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.86,
            ),
            itemCount: list.length,
            itemBuilder: (c, i) => _AlbumTile(album: list[i], roomId: roomId),
          );
        },
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final Album album;
  final String roomId;
  const _AlbumTile({required this.album, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/more/albums/$roomId/${album.id}'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadow.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (album.coverPublicId.isEmpty)
                Container(
                  color: AppColors.mint,
                  alignment: Alignment.center,
                  child: const Text('🍀', style: TextStyle(fontSize: 30)),
                )
              else
                Image.network(
                  Cloudinary.thumb(album.coverPublicId, size: 600),
                  fit: BoxFit.cover,
                  errorBuilder: (a, b, c) => Container(color: AppColors.mint),
                ),

              // 아래쪽 글자가 읽히도록 그라데이션
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                  ),
                ),
              ),

              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kFontFamily,
                        fontFamilyFallback: kFontFallback,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('yyyy.M.d').format(album.date)}'
                      '${album.photoCount > 0 ? ' · ${album.photoCount}장' : ''}',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontFamilyFallback: kFontFallback,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 앨범 만들기
Future<void> openAlbumEditor(BuildContext context, WidgetRef ref,
    {Album? album, String? roomId}) async {
  await openSheet(
    context,
    _AlbumEditor(
      album: album,
      roomId: roomId ?? ref.read(currentRoomIdProvider),
    ),
  );
}

class _AlbumEditor extends ConsumerStatefulWidget {
  final Album? album;
  final String roomId;
  const _AlbumEditor({this.album, required this.roomId});
  @override
  ConsumerState<_AlbumEditor> createState() => _AlbumEditorState();
}

class _AlbumEditorState extends ConsumerState<_AlbumEditor> {
  late final _title = TextEditingController(text: widget.album?.title ?? '');
  late DateTime _date = widget.album?.date ?? DateTime.now();
  String? _meetingId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _meetingId = widget.album?.meetingId.isNotEmpty == true
        ? widget.album!.meetingId
        : null;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      toast(context, '앨범 이름을 입력해주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = ref.read(myUidProvider)!;
      final data = {
        'title': _title.text.trim(),
        'date': Timestamp.fromDate(_date),
        'meetingId': _meetingId ?? '',
        'authorUid': widget.album?.authorUid ?? uid,
      };
      if (widget.album == null) {
        await Refs.albums(widget.roomId).add({
          ...data,
          'coverPublicId': '',
          'photoCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await Refs.albums(widget.roomId)
            .doc(widget.album!.id)
            .set(data, SetOptions(merge: true));
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
    final meetings =
        ref.watch(meetingsProvider(widget.roomId)).value ?? const <Meeting>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHandle(widget.album == null ? '앨범 만들기' : '앨범 수정',
            trailing: RoomBadge(widget.roomId)),
        TextField(
          controller: _title,
          decoration: const InputDecoration(
              labelText: '앨범 이름', hintText: '예: 2026 겨울 수련회'),
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
            decoration: const InputDecoration(labelText: '날짜'),
            child: Text(DateFormat('yyyy년 M월 d일').format(_date),
                style: const TextStyle(fontSize: 14)),
          ),
        ),
        if (meetings.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _meetingId,
            decoration: const InputDecoration(labelText: '연결할 모임 (선택)'),
            items: [
              const DropdownMenuItem(value: null, child: Text('연결 안 함')),
              for (final m in meetings.take(20))
                DropdownMenuItem(
                    value: m.id,
                    child: Text(
                        '${DateFormat('M/d').format(m.startAt)} ${m.title}',
                        overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _meetingId = v),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '저장 중...' : '저장하기'),
        ),
      ],
    );
  }
}
