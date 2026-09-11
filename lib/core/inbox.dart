import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import 'providers.dart';
import 'refs.dart';

/// 알림함 — 애기애타 앱의 제목 줄 종(알림 열기)과 같은 기능.
///
/// 애기애타는 서버가 notices 컬렉션에 알림을 한 건씩 적지만, 사랑방 앱은 서버가 없습니다.
/// 그래서 이미 있는 기록(모임·공지·투표·정산)을 내 분반 + 전체 사랑방에서 모아 최근 순으로 보여줍니다.
/// 새 컬렉션도 보안 규칙 변경도 필요 없습니다. 채팅은 넣지 않습니다(애기애타와 같음).
///
/// 마지막으로 알림함을 연 시각은 members/{uid}.noticesSeenAt 에 적습니다(본인 문서라 지금 규칙으로 쓸 수 있음).
enum InboxKind { meeting, notice, poll, settlement }

class InboxItem {
  final InboxKind kind;
  final String roomId, id, title, body, authorUid;
  final DateTime createdAt;

  const InboxItem({
    required this.kind,
    required this.roomId,
    required this.id,
    required this.title,
    required this.body,
    required this.authorUid,
    required this.createdAt,
  });

  /// 줄을 눌렀을 때 갈 화면. 공지·투표·정산은 방을 그 사랑방으로 바꾼 뒤 목록으로 갑니다.
  String get route => switch (kind) {
        InboxKind.meeting => '/meetings/$roomId/$id',
        InboxKind.notice => '/more/notices',
        InboxKind.poll => '/more/polls',
        InboxKind.settlement => '/more/settlements',
      };
}

/// 알림함에 보여줄 최대 줄 수 (애기애타와 같음)
const _inboxLimit = 50;

final inboxProvider = Provider<AsyncValue<List<InboxItem>>>((ref) {
  final items = <InboxItem>[];
  var waiting = false;
  Object? error;

  // createdAt 이 없는 기록(서버 시각이 아직 안 찍힌 방금 올린 것 등)은 넣지 않습니다.
  // 지금 시각으로 넣으면 볼 때마다 새 알림으로 켜집니다.
  void collect<T>(AsyncValue<List<T>> async, InboxItem? Function(T) toItem) {
    if (async.hasError) error ??= async.error;
    final list = async.value;
    if (list == null) {
      waiting = true;
      return;
    }
    for (final e in list) {
      final item = toItem(e);
      if (item != null) items.add(item);
    }
  }

  for (final room in ref.watch(myRoomsProvider)) {
    final r = room.id;
    collect<Meeting>(
      ref.watch(meetingsProvider(r)),
      (m) => m.createdAt == null
          ? null
          : InboxItem(
              kind: InboxKind.meeting,
              roomId: r,
              id: m.id,
              title: '새 모임 · ${m.title}',
              body:
                  '${room.name} · ${DateFormat('M월 d일 (E) a h:mm', 'ko_KR').format(m.startAt)}',
              authorUid: m.authorUid,
              createdAt: m.createdAt!,
            ),
    );
    collect<Notice>(
      ref.watch(noticesProvider(r)),
      (n) => n.createdAt == null
          ? null
          : InboxItem(
              kind: InboxKind.notice,
              roomId: r,
              id: n.id,
              title: '새 공지 · ${n.title}',
              body: n.body.split('\n').first,
              authorUid: n.authorUid,
              createdAt: n.createdAt!,
            ),
    );
    collect<Poll>(
      ref.watch(pollsProvider(r)),
      (p) => p.createdAt == null
          ? null
          : InboxItem(
              kind: InboxKind.poll,
              roomId: r,
              id: p.id,
              title: '새 투표 · ${p.question}',
              body: room.name,
              authorUid: p.authorUid,
              createdAt: p.createdAt!,
            ),
    );
    collect<Settlement>(
      ref.watch(settlementsProvider(r)),
      (s) => s.createdAt == null
          ? null
          : InboxItem(
              kind: InboxKind.settlement,
              roomId: r,
              id: s.id,
              title: '새 정산 · ${s.title}',
              body: room.name,
              authorUid: s.authorUid,
              createdAt: s.createdAt!,
            ),
    );
  }

  if (items.isEmpty && error != null) {
    return AsyncValue.error(error!, StackTrace.current);
  }
  if (items.isEmpty && waiting) return const AsyncValue.loading();
  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return AsyncValue.data(items.take(_inboxLimit).toList());
});

/// 종의 빨간 점 — 마지막으로 알림함을 연 뒤 **다른 사람이** 올린 것이 있으면 켜집니다.
/// 알림함을 한 번도 연 적이 없으면 가입한 시각을 기준으로 삼습니다(애기애타와 같음) —
/// 안 그러면 새로 들어온 사람에게 지난 기록 전부가 새 알림으로 켜집니다.
final inboxHasNewProvider = Provider<bool>((ref) {
  final uid = ref.watch(myUidProvider);
  final me = ref.watch(myMemberProvider);
  final since = me?.noticesSeenAt ?? me?.joinedAt;
  if (uid == null || since == null) return false;
  final items = ref.watch(inboxProvider).value ?? const <InboxItem>[];
  return items.any((i) => i.authorUid != uid && i.createdAt.isAfter(since));
});

/// 알림함을 열었을 때 "다 봤다"고 적습니다.
/// 서버 시각을 쓰면 확정되기 전 잠깐 값이 비어 빨간 점이 깜빡여서, 기기 시각을 씁니다.
Future<void> markInboxSeen(String uid) => Refs.member(uid).set(
      {'noticesSeenAt': Timestamp.fromDate(DateTime.now())},
      SetOptions(merge: true),
    );
