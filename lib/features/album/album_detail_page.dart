import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_config.dart';
import '../../core/cloudinary.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../models/models.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'albums_page.dart';

class AlbumDetailPage extends ConsumerStatefulWidget {
  final String roomId, albumId;
  const AlbumDetailPage(
      {super.key, required this.roomId, required this.albumId});

  @override
  ConsumerState<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends ConsumerState<AlbumDetailPage> {
  bool _uploading = false;
  int _done = 0, _total = 0;
  bool _keepOriginal = false;

  Future<void> _pickAndUpload() async {
    if (!AppConfig.isCloudinaryConfigured) {
      toast(context, 'lib/app_config.dart 에 Cloudinary 값을 먼저 넣어주세요.');
      return;
    }
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty) return;

    setState(() {
      _uploading = true;
      _done = 0;
      _total = files.length;
    });

    final uid = ref.read(myUidProvider)!;
    var failed = 0;
    String? firstPublicId;

    for (final f in files) {
      try {
        final bytes = await f.readAsBytes();
        final up = await Cloudinary.upload(bytes, f.name,
            keepOriginal: _keepOriginal);
        firstPublicId ??= up.publicId;
        await Refs.photos(widget.roomId, widget.albumId).add({
          'publicId': up.publicId,
          'width': up.width,
          'height': up.height,
          'bytes': up.bytes,
          'format': up.format,
          'uploaderUid': uid,
          'likes': <String>[],
          'hidden': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        failed++;
        if (mounted && failed == 1) toast(context, '업로드 실패: $e');
      }
      if (mounted) setState(() => _done++);
    }

    // 커버가 없으면 첫 장을 커버로, 장수 갱신
    try {
      final album = ref.read(albumsProvider(widget.roomId)).value
          ?.where((a) => a.id == widget.albumId)
          .firstOrNull;
      final count = (await Refs.photos(widget.roomId, widget.albumId).count().get()).count ?? 0;
      await Refs.albums(widget.roomId).doc(widget.albumId).set({
        'photoCount': count,
        if ((album?.coverPublicId ?? '').isEmpty && firstPublicId != null)
          'coverPublicId': firstPublicId,
      }, SetOptions(merge: true));
    } catch (_) {}

    if (mounted) {
      setState(() => _uploading = false);
      toast(context,
          failed == 0 ? '${files.length}장 올렸어요 📸' : '$failed장 실패했어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final albums = ref.watch(albumsProvider(widget.roomId)).value;
    final album = albums?.where((a) => a.id == widget.albumId).firstOrNull;
    final photos = ref.watch(photosProvider((widget.roomId, widget.albumId)));
    final uid = ref.watch(myUidProvider);

    if (albums == null) return const SubPage(title: '앨범', body: Loading());
    if (album == null) {
      return const SubPage(
          title: '앨범', body: EmptyState(emoji: '🔍', title: '없는 앨범이에요'));
    }

    return SubPage(
      title: album.title,
      fallbackRoute: '/more/albums',
      actions: [
        if (album.authorUid == uid)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) async {
              if (v == 'edit') {
                openAlbumEditor(context, ref, album: album, roomId: widget.roomId);
              } else if (v == 'delete') {
                final ok = await confirm(context,
                    title: '앨범을 삭제할까요?',
                    message: '앱에서는 사라지지만 Cloudinary 원본은 남습니다.',
                    ok: '삭제',
                    danger: true);
                if (ok) {
                  await Refs.albums(widget.roomId).doc(album.id).delete();
                  if (context.mounted) context.go('/more/albums');
                }
              }
            },
            itemBuilder: (c) => const [
              PopupMenuItem(value: 'edit', child: Text('앨범 정보 수정')),
              PopupMenuItem(value: 'delete', child: Text('앨범 삭제')),
            ],
          ),
      ],
      fab: _uploading
          ? null
          : FloatingActionButton.extended(
              onPressed: _pickAndUpload,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('사진 올리기'),
            ),
      body: Column(
        children: [
          if (AppConfig.cloudinaryOriginalPreset.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _keepOriginal,
                onChanged: (v) => setState(() => _keepOriginal = v),
                title: const Text('원본 그대로 올리기',
                    style: TextStyle(fontSize: 13)),
                subtitle: const Text('끄면 긴 변 2560px으로 줄여서 올립니다',
                    style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
              ),
            ),
          if (_uploading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _total == 0 ? null : _done / _total,
                      minHeight: 6,
                      backgroundColor: AppColors.fill,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('$_done / $_total 장 올리는 중...',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkMuted)),
                ],
              ),
            ),
          Expanded(
            child: photos.when(
              loading: () => const Loading(),
              error: (e, _) => ErrorNote(e),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    emoji: '🖼️',
                    title: '아직 사진이 없어요',
                    subtitle: '아래 버튼으로 여러 장 한 번에 올릴 수 있어요.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: list.length,
                  itemBuilder: (c, i) => GestureDetector(
                    onTap: () => _openViewer(list, i),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            Cloudinary.thumb(list[i].publicId),
                            fit: BoxFit.cover,
                            errorBuilder: (a, b, c) =>
                                Container(color: AppColors.brand50),
                          ),
                        ),
                        if (list[i].likes.isNotEmpty)
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text('❤️ ${list[i].likes.length}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openViewer(List<Photo> photos, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (c) => _PhotoViewer(
        roomId: widget.roomId,
        albumId: widget.albumId,
        photos: photos,
        initialIndex: index,
      ),
    );
  }
}

// ─────────────────────────────────────────── 사진 뷰어
class _PhotoViewer extends ConsumerStatefulWidget {
  final String roomId, albumId;
  final List<Photo> photos;
  final int initialIndex;
  const _PhotoViewer({
    required this.roomId,
    required this.albumId,
    required this.photos,
    required this.initialIndex,
  });

  @override
  ConsumerState<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends ConsumerState<_PhotoViewer> {
  late final _pc = PageController(initialPage: widget.initialIndex);
  late int _i = widget.initialIndex;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(Photo p) async {
    final uid = ref.read(myUidProvider);
    if (uid == null) return;
    await Refs.photos(widget.roomId, widget.albumId).doc(p.id).update({
      'likes': p.likes.contains(uid)
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(photosProvider((widget.roomId, widget.albumId))).value ??
        widget.photos;
    final photos = live.isEmpty ? widget.photos : live;
    final i = _i.clamp(0, photos.length - 1);
    final p = photos[i];
    final uid = ref.watch(myUidProvider);
    final members = ref.watch(memberMapProvider);

    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: photos.length,
            onPageChanged: (v) => setState(() => _i = v),
            itemBuilder: (c, idx) => InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.network(
                  Cloudinary.large(photos[idx].publicId),
                  fit: BoxFit.contain,
                  loadingBuilder: (c, w, ev) => ev == null
                      ? w
                      : const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)),
                  errorBuilder: (a, b, c) => const Center(
                      child: Text('불러오지 못했어요',
                          style: TextStyle(color: Colors.white))),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text('${i + 1} / ${photos.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                    const Spacer(),
                    if (p.uploaderUid == uid)
                      IconButton(
                        tooltip: p.cancellable ? '완전 삭제' : '앱에서 숨기기',
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.white),
                        onPressed: () async {
                          final ok = await confirm(
                            context,
                            title: p.cancellable ? '이 사진을 삭제할까요?' : '앱에서 숨길까요?',
                            message: p.cancellable
                                ? '올린 지 10분 안이라 기록이 완전히 지워집니다.'
                                : 'Cloudinary 원본은 남습니다.\n완전 삭제는 Cloudinary 대시보드에서 가능해요.',
                            ok: p.cancellable ? '삭제' : '숨기기',
                            danger: true,
                          );
                          if (!ok) return;
                          if (p.cancellable) {
                            await Refs.photos(widget.roomId, widget.albumId).doc(p.id).delete();
                          } else {
                            await Refs.photos(widget.roomId, widget.albumId)
                                .doc(p.id)
                                .update({'hidden': true});
                          }
                          if (context.mounted) Navigator.pop(context);
                        },
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        p.likes.contains(uid)
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: p.likes.contains(uid)
                            ? const Color(0xFFF06B7E)
                            : Colors.white,
                      ),
                      onPressed: () => _toggleLike(p),
                    ),
                    Text('${p.likes.length}',
                        style: const TextStyle(color: Colors.white)),
                    const Spacer(),
                    if (p.uploaderUid.isNotEmpty)
                      Text(
                        '${members[p.uploaderUid]?.display ?? ''}'
                        '${p.createdAt != null ? ' · ${DateFormat('M/d').format(p.createdAt!)}' : ''}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12),
                      ),
                    const Spacer(),
                    IconButton(
                      tooltip: '원본 다운로드',
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.white),
                      onPressed: () => launchUrl(
                        Uri.parse(Cloudinary.download(p.publicId)),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
