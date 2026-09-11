import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_config.dart';

/// Firestore 경로 모음.
///
/// ```
/// groups/nw2026
///   ├ members/{uid}                프로필은 청년부 전체에서 하나 (roomId 로 분반 표시)
///   └ rooms/{roomId}               hj / pg / all
///        ├ weeks/{w}/prayers/…     기도제목 — 분반 사랑방에만
///        ├ routineLogs, prayerReactions
///        ├ meetings, albums, notices, polls, settlements, sermonNotes
///        └ messages                채팅
/// ```
class Refs {
  Refs._();
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> get group =>
      db.collection('groups').doc(AppConfig.groupId);

  // ── 프로필 (청년부 공통) ───────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get members =>
      group.collection('members');
  static DocumentReference<Map<String, dynamic>> member(String uid) =>
      members.doc(uid);
  static CollectionReference<Map<String, dynamic>> birthdayCards(
          String uid, String year) =>
      member(uid).collection('birthdayCards').doc(year).collection('messages');

  // ── 사랑방 ────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> get rooms =>
      group.collection('rooms');
  static DocumentReference<Map<String, dynamic>> room(String roomId) =>
      rooms.doc(roomId);

  // ── 기도제목 (분반 사랑방 전용) ─────────────────────────────
  static CollectionReference<Map<String, dynamic>> weeks(String roomId) =>
      room(roomId).collection('weeks');
  static DocumentReference<Map<String, dynamic>> week(
          String roomId, String weekId) =>
      weeks(roomId).doc(weekId);
  static CollectionReference<Map<String, dynamic>> prayers(
          String roomId, String weekId) =>
      week(roomId, weekId).collection('prayers');
  static DocumentReference<Map<String, dynamic>> prayer(
          String roomId, String weekId, String uid) =>
      prayers(roomId, weekId).doc(uid);

  /// 나만 보기 항목 — 규칙상 본인 외 아무도 못 읽습니다.
  static DocumentReference<Map<String, dynamic>> prayerPrivate(
          String roomId, String weekId, String uid) =>
      prayer(roomId, weekId, uid).collection('private').doc('items');

  /// 🙏 기도했어요 — 기도제목 문서는 본인만 쓸 수 있으므로 반응은 별도 컬렉션에
  static CollectionReference<Map<String, dynamic>> prayerReactions(
          String roomId) =>
      room(roomId).collection('prayerReactions');
  static String reactionId(
          String weekId, String targetUid, int topicIndex, String uid) =>
      '${weekId}__${targetUid}__${topicIndex}__$uid';

  // ── 신앙루틴 체크 ──────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> routineLogs(String roomId) =>
      room(roomId).collection('routineLogs');
  static DocumentReference<Map<String, dynamic>> routineLog(
          String roomId, String uid, String date) =>
      routineLogs(roomId).doc('${uid}_$date');

  // ── 채팅 ──────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> messages(String roomId) =>
      room(roomId).collection('messages');

  // ── 모임 / 출석 ────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> meetings(String roomId) =>
      room(roomId).collection('meetings');
  static CollectionReference<Map<String, dynamic>> attendance(
          String roomId, String meetingId) =>
      meetings(roomId).doc(meetingId).collection('attendance');

  // ── 앨범 / 사진 ────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> albums(String roomId) =>
      room(roomId).collection('albums');
  static CollectionReference<Map<String, dynamic>> photos(
          String roomId, String albumId) =>
      albums(roomId).doc(albumId).collection('photos');

  // ── 그 외 ─────────────────────────────────────────────────
  static CollectionReference<Map<String, dynamic>> notices(String roomId) =>
      room(roomId).collection('notices');
  static CollectionReference<Map<String, dynamic>> polls(String roomId) =>
      room(roomId).collection('polls');
  static CollectionReference<Map<String, dynamic>> settlements(String roomId) =>
      room(roomId).collection('settlements');
  static CollectionReference<Map<String, dynamic>> sermonNotes(String roomId) =>
      room(roomId).collection('sermonNotes');
}
