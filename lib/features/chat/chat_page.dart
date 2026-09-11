import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/room_switch.dart';

/// 사랑방 채팅. 방마다 하나씩 (분반 / 전체).
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});
  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    final uid = ref.read(myUidProvider);
    final roomId = ref.read(currentRoomIdProvider);
    if (text.isEmpty || uid == null || _sending) return;

    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await Refs.messages(roomId).add({
        'uid': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        _ctrl.text = text; // 실패하면 입력값을 돌려줍니다
        toast(context, '전송 실패: $e');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomId = ref.watch(currentRoomIdProvider);
    final room = ref.watch(currentRoomProvider);
    final async = ref.watch(messagesProvider(roomId));
    final members = ref.watch(memberMapProvider);
    final myUid = ref.watch(myUidProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(child: RoomSwitchChip(compact: true)),
          ),
        ],
      ),
      body: SafeArea(
        child: Bounded(
          child: Column(
            children: [
              Expanded(
                child: async.when(
                  loading: () => const Loading(),
                  error: (e, _) => ErrorNote(e),
                  data: (msgs) {
                    if (msgs.isEmpty) {
                      return EmptyState(
                        emoji: '💬',
                        title: '${room.name} 채팅이 비어 있어요',
                        subtitle: '첫 마디를 남겨보세요.\n'
                            '길게 남길 이야기는 공지나 말씀노트에 쓰면 안 묻힙니다.',
                      );
                    }
                    // 최신이 위로 오는 스트림을 reverse 리스트로 그립니다
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      itemCount: msgs.length,
                      itemBuilder: (c, i) {
                        final m = msgs[i];
                        final prev = i + 1 < msgs.length ? msgs[i + 1] : null;
                        final next = i > 0 ? msgs[i - 1] : null;
                        return _Bubble(
                          message: m,
                          author: members[m.uid],
                          isMine: m.uid == myUid,
                          // 같은 사람이 이어서 쓰면 이름/사진을 생략
                          showHeader: prev == null || prev.uid != m.uid,
                          showTime: next == null ||
                              next.uid != m.uid ||
                              !_sameMinute(m.createdAt, next.createdAt),
                          dateDivider: _dateDividerFor(m, prev),
                        );
                      },
                    );
                  },
                ),
              ),
              _Composer(
                controller: _ctrl,
                focusNode: _focus,
                sending: _sending,
                onSend: _send,
                hint: '${room.name}에 메시지 보내기',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _sameMinute(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  /// 날짜가 바뀌는 지점에 구분선을 넣습니다 (prev = 시간상 앞선 메시지)
  static String? _dateDividerFor(ChatMessage m, ChatMessage? prev) {
    final t = m.createdAt;
    if (t == null) return null;
    final p = prev?.createdAt;
    if (p != null && p.year == t.year && p.month == t.month && p.day == t.day) {
      return null;
    }
    return DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(t);
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final Member? author;
  final bool isMine, showHeader, showTime;
  final String? dateDivider;

  const _Bubble({
    required this.message,
    required this.author,
    required this.isMine,
    required this.showHeader,
    required this.showTime,
    this.dateDivider,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Flexible(
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.text));
          toast(context, '메시지를 복사했어요');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: isMine ? AppColors.brand : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMine || !showHeader ? 16 : 4),
              topRight: Radius.circular(isMine && showHeader ? 4 : 16),
              bottomLeft: const Radius.circular(16),
              bottomRight: const Radius.circular(16),
            ),
            boxShadow: isMine ? null : AppShadow.card,
          ),
          child: SelectableText(
            message.text,
            style: AppText.body.copyWith(
              fontSize: 14,
              height: 1.5,
              color: isMine ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );

    final time = showTime && message.createdAt != null
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(DateFormat('a h:mm', 'ko_KR').format(message.createdAt!),
                style: AppText.micro.copyWith(fontSize: 10)),
          )
        : const SizedBox(width: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dateDivider != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.brand50,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(dateDivider!,
                    style: AppText.micro.copyWith(color: AppColors.brand)),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(top: showHeader ? 10 : 3),
          child: Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                SizedBox(
                  width: 32,
                  child: showHeader
                      ? Avatar(member: author, size: 32)
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
              ],
              if (isMine) time,
              if (!isMine)
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHeader)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 2),
                          child: Text(author?.display ?? '이름없음',
                              style: AppText.micro),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [bubble, time],
                      ),
                    ],
                  ),
                )
              else
                bubble,
            ],
          ),
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final String hint;

  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  fillColor: AppColors.fill,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    borderSide: const BorderSide(color: AppColors.brand, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              height: 46,
              child: FilledButton(
                onPressed: sending ? null : onSend,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(46, 46),
                ),
                child: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.arrow_upward_rounded, size: 20),
              ),
            ),
          ],
        ),
      );
}
