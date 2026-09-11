import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_config.dart';
import '../models/models.dart';
import 'refs.dart';
import 'week.dart';

// ─────────────────────────────────────────── 인증
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

final myUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).value?.uid,
);

/// 로그인 직후 members/{uid} 문서를 만들어 둡니다 (승인 절차 없음).
Future<void> ensureMemberDoc(User user) async {
  final ref = Refs.member(user.uid);
  final snap = await ref.get();
  if (!snap.exists) {
    await ref.set({
      'name': user.displayName ?? '',
      'nickname': '',
      'photoUrl': user.photoURL ?? '',
      'birthday': '',
      'bio': '',
      'roomId': '',
      'joinedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  } else {
    await ref.set({'lastSeenAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }
}

Future<UserCredential> signInWithGoogle() {
  final provider = GoogleAuthProvider()
    ..setCustomParameters({'prompt': 'select_account'});
  return FirebaseAuth.instance.signInWithPopup(provider);
}

Future<void> signOut() => FirebaseAuth.instance.signOut();

// ─────────────────────────────────────────── 청년부 / 멤버
final groupProvider = StreamProvider<Map<String, dynamic>>((ref) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.group.snapshots().map((d) => d.data() ?? <String, dynamic>{});
});

final membersProvider = StreamProvider<List<Member>>((ref) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.members.snapshots().map((s) {
    final list = s.docs.map(Member.fromDoc).toList();
    list.sort((a, b) => a.display.compareTo(b.display));
    return list;
  });
});

final memberMapProvider = Provider<Map<String, Member>>((ref) {
  final list = ref.watch(membersProvider).value ?? const <Member>[];
  return {for (final m in list) m.uid: m};
});

final myMemberProvider = Provider<Member?>((ref) {
  final uid = ref.watch(myUidProvider);
  if (uid == null) return null;
  return ref.watch(memberMapProvider)[uid];
});

// ─────────────────────────────────────────── 사랑방
/// 내 분반 사랑방 (hj / pg). 아직 안 고른 사람은 빈 문자열.
final myRoomIdProvider = Provider<String>(
  (ref) => ref.watch(myMemberProvider)?.roomId ?? '',
);

/// 지금 보고 있는 사랑방. 기본값은 내 분반, 전체 사랑방으로 전환 가능.
final _selectedRoomProvider = StateProvider<String?>((ref) => null);

final currentRoomIdProvider = Provider<String>((ref) {
  final selected = ref.watch(_selectedRoomProvider);
  final mine = ref.watch(myRoomIdProvider);
  if (selected != null && AppConfig.isValidRoom(selected)) return selected;
  return mine.isNotEmpty ? mine : AppConfig.allRoomId;
});

final currentRoomProvider = Provider<SarangRoom>(
  (ref) => AppConfig.roomOf(ref.watch(currentRoomIdProvider)),
);

/// 내가 들어갈 수 있는 사랑방 = 내 분반 + 전체
final myRoomsProvider = Provider<List<SarangRoom>>((ref) {
  final mine = ref.watch(myRoomIdProvider);
  return [
    if (mine.isNotEmpty) AppConfig.roomOf(mine),
    AppConfig.roomOf(AppConfig.allRoomId),
  ];
});

void switchRoom(WidgetRef ref, String roomId) =>
    ref.read(_selectedRoomProvider.notifier).state = roomId;

/// 그 사랑방에 속한 멤버 (전체 사랑방이면 모두)
final roomMembersProvider =
    Provider.family<List<Member>, String>((ref, roomId) {
  final all = ref.watch(membersProvider).value ?? const <Member>[];
  if (AppConfig.roomOf(roomId).isAll) return all;
  return all.where((m) => m.roomId == roomId).toList();
});

/// 지금 사랑방의 멤버
final currentRoomMembersProvider = Provider<List<Member>>(
  (ref) => ref.watch(roomMembersProvider(ref.watch(currentRoomIdProvider))),
);

/// 내 분반 사랑방 멤버 (기도제목은 여기서만 오갑니다)
final myRoomMembersProvider = Provider<List<Member>>(
  (ref) => ref.watch(roomMembersProvider(ref.watch(myRoomIdProvider))),
);

final isLeaderProvider = Provider<bool>((ref) {
  final uid = ref.watch(myUidProvider);
  final g = ref.watch(groupProvider).value;
  if (uid == null || g == null) return false;
  final admins = (g['admins'] as List?)?.map((e) => e.toString()).toList() ?? [];
  return g['leaderUid'] == uid || admins.contains(uid);
});

/// 이번 달 생일자 (청년부 전체)
final birthdayThisMonthProvider = Provider<List<Member>>((ref) {
  final now = DateTime.now();
  final list = (ref.watch(membersProvider).value ?? const <Member>[])
      .where((m) => m.birthMonth == now.month)
      .toList();
  list.sort((a, b) => (a.birthDay ?? 99).compareTo(b.birthDay ?? 99));
  return list;
});

// ─────────────────────────────────────────── 주차 선택
final selectedWeekProvider = StateProvider<Week>((ref) => Week.current());

// ─────────────────────────────────────────── 기도제목 (분반 사랑방 전용)
final _publicPrayersProvider = StreamProvider.family<
    List<DocumentSnapshot<Map<String, dynamic>>>, String>((ref, weekId) {
  final room = ref.watch(myRoomIdProvider);
  if (ref.watch(myUidProvider) == null || room.isEmpty) {
    return const Stream.empty();
  }
  return Refs.prayers(room, weekId)
      .where('visibility', isEqualTo: 'all')
      .snapshots()
      .map((s) => s.docs);
});

final _myPrivatePrayerProvider = StreamProvider.family<
    DocumentSnapshot<Map<String, dynamic>>?, String>((ref, weekId) {
  final uid = ref.watch(myUidProvider);
  final room = ref.watch(myRoomIdProvider);
  if (uid == null || room.isEmpty) return Stream.value(null);
  return Refs.prayerPrivate(room, weekId, uid).snapshots();
});

/// 그 주차 우리 분반의 기도제목. 내 "나만 보기"는 나에게만 합쳐집니다.
final prayerEntriesProvider =
    Provider.family<AsyncValue<List<PrayerEntry>>, String>((ref, weekId) {
  final pub = ref.watch(_publicPrayersProvider(weekId));
  final priv = ref.watch(_myPrivatePrayerProvider(weekId));
  final uid = ref.watch(myUidProvider);

  return pub.whenData((docs) {
    final privDoc = priv.value;
    final entries = docs
        .map((d) => PrayerEntry.fromDocs(d, d.id == uid ? privDoc : null))
        .toList();
    entries.sort((a, b) => (b.updatedAt ?? DateTime(2000))
        .compareTo(a.updatedAt ?? DateTime(2000)));
    return entries;
  });
});

/// 내 이번 주 기도제목 (없으면 null)
final myPrayerProvider = Provider.family<PrayerEntry?, String>((ref, weekId) {
  final uid = ref.watch(myUidProvider);
  final list = ref.watch(prayerEntriesProvider(weekId)).value;
  if (uid == null || list == null) return null;
  for (final e in list) {
    if (e.uid == uid) return e;
  }
  return null;
});

/// 우리 분반에서 아직 안 낸 사람들
final notSubmittedProvider =
    Provider.family<List<Member>, String>((ref, weekId) {
  final members = ref.watch(myRoomMembersProvider);
  final entries = ref.watch(prayerEntriesProvider(weekId)).value;
  if (entries == null) return const [];
  // 공개 문서는 저장할 때마다 updatedAt 이 찍히므로 "냈다"의 기준이 됩니다.
  // (나만 보기 항목만 쓴 사람도 제출로 인정)
  final done = {
    for (final e in entries)
      if (e.updatedAt != null || e.topics.isNotEmpty || e.routines.isNotEmpty)
        e.uid
  };
  return members.where((m) => !done.contains(m.uid)).toList();
});

/// 🙏 반응 — key: "targetUid#topicIndex" → 기도해준 사람 uid 목록
final prayerReactionsProvider =
    StreamProvider.family<Map<String, List<String>>, String>((ref, weekId) {
  final room = ref.watch(myRoomIdProvider);
  if (ref.watch(myUidProvider) == null || room.isEmpty) {
    return const Stream.empty();
  }
  return Refs.prayerReactions(room)
      .where('weekId', isEqualTo: weekId)
      .snapshots()
      .map((s) {
    final out = <String, List<String>>{};
    for (final d in s.docs) {
      final m = d.data();
      final key = '${m['targetUid']}#${m['topicIndex']}';
      (out[key] ??= []).add((m['uid'] ?? '') as String);
    }
    return out;
  });
});

// ─────────────────────────────────────────── 신앙루틴 체크 (분반)
final myRoutineTodayProvider = StreamProvider<List<int>>((ref) {
  final uid = ref.watch(myUidProvider);
  final room = ref.watch(myRoomIdProvider);
  if (uid == null || room.isEmpty) return Stream.value(const []);
  return Refs.routineLog(room, uid, today()).snapshots().map((d) =>
      ((d.data()?['done'] as List?) ?? [])
          .map((e) => (e as num).toInt())
          .toList());
});

/// 내 연속 체크 일수 (오늘 또는 어제부터 거슬러 올라감)
final myStreakProvider = FutureProvider<int>((ref) async {
  final uid = ref.watch(myUidProvider);
  final room = ref.watch(myRoomIdProvider);
  if (uid == null || room.isEmpty) return 0;
  ref.watch(myRoutineTodayProvider); // 오늘 체크가 바뀌면 다시 계산

  // 문서 ID 가 "{uid}_{YYYY-MM-DD}" 이므로 ID 범위로 훑습니다.
  // (uid + date 복합 인덱스를 만들지 않아도 되도록)
  final from = DateTime.now().subtract(const Duration(days: 120));
  final snap = await Refs.routineLogs(room)
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${uid}_${ymd(from)}')
      .where(FieldPath.documentId, isLessThanOrEqualTo: '${uid}_9999-99-99')
      .get();

  final doneDays = <String>{};
  for (final d in snap.docs) {
    final data = d.data();
    final done = (data['done'] as List?) ?? const [];
    if (done.isNotEmpty) doneDays.add((data['date'] ?? '') as String);
  }
  if (doneDays.isEmpty) return 0;

  var cursor = DateTime.now();
  if (!doneDays.contains(ymd(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!doneDays.contains(ymd(cursor))) return 0;
  }
  var n = 0;
  while (doneDays.contains(ymd(cursor))) {
    n++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return n;
});

/// 오늘 우리 분반에서 루틴을 체크한 인원
final todayRoutineCountProvider = StreamProvider<int>((ref) {
  final room = ref.watch(myRoomIdProvider);
  if (ref.watch(myUidProvider) == null || room.isEmpty) return Stream.value(0);
  return Refs.routineLogs(room)
      .where('date', isEqualTo: today())
      .snapshots()
      .map((s) => s.docs
          .where((d) => ((d.data()['done'] as List?) ?? []).isNotEmpty)
          .length);
});

// ─────────────────────────────────────────── 채팅
final messagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.messages(roomId)
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
});

// ─────────────────────────────────────────── 모임
final meetingsProvider =
    StreamProvider.family<List<Meeting>, String>((ref, roomId) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.meetings(roomId)
      .orderBy('startAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Meeting.fromDoc).toList());
});

/// 지금 사랑방의 모임
final currentMeetingsProvider = Provider<AsyncValue<List<Meeting>>>(
  (ref) => ref.watch(meetingsProvider(ref.watch(currentRoomIdProvider))),
);

/// 홈 배너용 — 내 분반 + 전체 사랑방을 통틀어 가장 가까운 모임
final nextMeetingProvider = Provider<(String, Meeting)?>((ref) {
  final out = <(String, Meeting)>[];
  for (final r in ref.watch(myRoomsProvider)) {
    final list = ref.watch(meetingsProvider(r.id)).value ?? const <Meeting>[];
    for (final m in list) {
      if (m.isUpcoming) out.add((r.id, m));
    }
  }
  if (out.isEmpty) return null;
  out.sort((a, b) => a.$2.startAt.compareTo(b.$2.startAt));
  return out.first;
});

final attendanceProvider = StreamProvider.family<
    Map<String, Map<String, dynamic>>, (String, String)>((ref, key) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.attendance(key.$1, key.$2).snapshots().map(
        (s) => {for (final d in s.docs) d.id: d.data()},
      );
});

// ─────────────────────────────────────────── 앨범 / 사진
final albumsProvider =
    StreamProvider.family<List<Album>, String>((ref, roomId) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.albums(roomId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Album.fromDoc).toList());
});

final currentAlbumsProvider = Provider<AsyncValue<List<Album>>>(
  (ref) => ref.watch(albumsProvider(ref.watch(currentRoomIdProvider))),
);

final photosProvider =
    StreamProvider.family<List<Photo>, (String, String)>((ref, key) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.photos(key.$1, key.$2)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map(Photo.fromDoc).where((p) => !p.hidden).toList());
});

/// 홈 미리보기용 — 지금 사랑방의 가장 최근 앨범 사진 몇 장
final recentPhotosProvider = StreamProvider<List<(String, Photo)>>((ref) {
  final roomId = ref.watch(currentRoomIdProvider);
  final albums = ref.watch(albumsProvider(roomId)).value;
  if (albums == null || albums.isEmpty) return Stream.value(const []);
  final a = albums.first;
  return Refs.photos(roomId, a.id)
      .orderBy('createdAt', descending: true)
      .limit(4)
      .snapshots()
      .map((s) => s.docs
          .map(Photo.fromDoc)
          .where((p) => !p.hidden)
          .map((p) => (a.id, p))
          .toList());
});

// ─────────────────────────────────────────── 공지 / 투표 / 정산 / 노트
final noticesProvider =
    StreamProvider.family<List<Notice>, String>((ref, roomId) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.notices(roomId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) {
    final list = s.docs.map(Notice.fromDoc).toList();
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000));
    });
    return list;
  });
});

final currentNoticesProvider = Provider<AsyncValue<List<Notice>>>(
  (ref) => ref.watch(noticesProvider(ref.watch(currentRoomIdProvider))),
);

/// 홈 고정 공지 — 내 분반 + 전체 사랑방 양쪽
final pinnedNoticesProvider = Provider<List<(String, Notice)>>((ref) {
  final out = <(String, Notice)>[];
  for (final r in ref.watch(myRoomsProvider)) {
    final list = ref.watch(noticesProvider(r.id)).value ?? const <Notice>[];
    for (final n in list.where((n) => n.pinned)) {
      out.add((r.id, n));
    }
  }
  out.sort((a, b) => (b.$2.createdAt ?? DateTime(2000))
      .compareTo(a.$2.createdAt ?? DateTime(2000)));
  return out;
});

final pollsProvider = StreamProvider.family<List<Poll>, String>((ref, roomId) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.polls(roomId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Poll.fromDoc).toList());
});

final currentPollsProvider = Provider<AsyncValue<List<Poll>>>(
  (ref) => ref.watch(pollsProvider(ref.watch(currentRoomIdProvider))),
);

final settlementsProvider =
    StreamProvider.family<List<Settlement>, String>((ref, roomId) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.settlements(roomId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Settlement.fromDoc).toList());
});

final currentSettlementsProvider = Provider<AsyncValue<List<Settlement>>>(
  (ref) => ref.watch(settlementsProvider(ref.watch(currentRoomIdProvider))),
);

final sermonNotesProvider =
    StreamProvider.family<List<SermonNote>, String>((ref, roomId) {
  if (ref.watch(myUidProvider) == null) return const Stream.empty();
  return Refs.sermonNotes(roomId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SermonNote.fromDoc).toList());
});

final currentSermonNotesProvider = Provider<AsyncValue<List<SermonNote>>>(
  (ref) => ref.watch(sermonNotesProvider(ref.watch(currentRoomIdProvider))),
);
