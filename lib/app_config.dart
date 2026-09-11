import 'package:firebase_core/firebase_core.dart';

/// ============================================================
///  ✅ 설정 완료 (2026-08-30) — 더 채울 값 없습니다.
///
///  Firebase   : church-c97c0  (Spark 무료, Auth + Firestore)
///  Cloudinary : dqldsminx     (Free, 프리셋 2종)
///
///  ※ 이 값들은 브라우저에 노출되어도 되는 값입니다(비밀번호 아님).
///    실제 보안은 Firestore 보안 규칙이 담당합니다.
/// ============================================================
/// 사랑방 하나. 분반 사랑방 2개 + 전체 사랑방 1개.
class SarangRoom {
  final String id, name;

  /// 전체 사랑방 — 모든 멤버가 자동으로 들어갑니다. 기도제목은 올리지 않습니다.
  final bool isAll;

  const SarangRoom({
    required this.id,
    required this.name,
    this.isAll = false,
  });
}

class AppConfig {
  AppConfig._();

  // ── 청년부 (고정) ───────────────────────────────────────────
  /// Firestore 최상위 경로 `groups/{groupId}`. 배포 빌드는 늘 `nw2026` 입니다.
  /// 테스트할 때만 `--dart-define=GROUP_ID=nw2026-test` 로 띄우면
  /// 멤버들의 실제 기록과 섞이지 않는 별도 공간에 씁니다 (규칙은 {gid} 공통이라 그대로).
  static const String groupId =
      String.fromEnvironment('GROUP_ID', defaultValue: 'nw2026');
  static const String groupName = '2026 뉴웨이브';

  /// 홈 화면 맨 위 제목
  static const String homeTitle = '할렐루야 사랑방';

  // ── 사랑방 목록 ────────────────────────────────────────────
  /// 이름을 바꾸고 싶으면 여기만 고치면 됩니다. `id` 는 절대 바꾸지 마세요
  /// (id 가 Firestore 경로라, 바꾸면 기존 기록이 안 보입니다).
  static const List<SarangRoom> rooms = [
    SarangRoom(id: 'hj', name: '희진사랑방'),
    SarangRoom(id: 'pg', name: '평강사랑방'),
    SarangRoom(id: 'all', name: '전체 사랑방', isAll: true),
  ];

  static const String allRoomId = 'all';

  /// 분반 사랑방만 (전체 제외) — 첫 진입 시 고르는 목록
  static List<SarangRoom> get classRooms =>
      rooms.where((r) => !r.isAll).toList();

  static SarangRoom roomOf(String id) => rooms.firstWhere(
        (r) => r.id == id,
        orElse: () => rooms.firstWhere((r) => r.isAll),
      );

  static bool isValidRoom(String id) => rooms.any((r) => r.id == id);

  // ── Firebase ──────────────────────────────────────────────
  static const String firebaseApiKey = 'AIzaSyA0Aesa1pnI36I2KbkgZd0Zd-QsCMWSPfo';
  static const String firebaseAuthDomain = 'church-c97c0.firebaseapp.com';
  static const String firebaseProjectId = 'church-c97c0';
  static const String firebaseMessagingSenderId = '1094696874902';
  static const String firebaseAppId = '1:1094696874902:web:192b787fdb6468bc3123b7';
  static const String firebaseStorageBucket = ''; // Storage 미사용 (사진은 Cloudinary)

  /// 웹 푸시 인증서 공개 키 (Firebase 콘솔 → 프로젝트 설정 → 클라우드 메시징 → 웹 푸시 인증서).
  /// 브라우저에 공개되는 값입니다. 비어 있으면 설정의 알림 켜기가 "아직 준비되지 않았어요"로 막힙니다.
  static const String firebaseVapidKey = '';

  // ── Cloudinary (사진) ──────────────────────────────────────
  static const String cloudinaryCloudName = 'dqldsminx';
  static const String cloudinaryUploadPreset = 'sarangbang_std';

  /// 선택: "원본 그대로 올리기" 토글을 쓰려면
  /// Incoming Transformation 을 비운 Unsigned 프리셋을 하나 더 만들고
  /// 그 이름을 여기에 넣으세요. (비워두면 토글이 숨겨집니다)
  static const String cloudinaryOriginalPreset = 'sarangbang_orig';

  // ── 표시 설정 ──────────────────────────────────────────────
  /// true  → 별칭 우선 (평강, 나단, 샤인 …)
  /// false → 실명 우선 (홍혜원 …)
  static const bool preferNickname = true;

  // ── 판정 헬퍼 ──────────────────────────────────────────────
  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseMessagingSenderId.isNotEmpty;

  static bool get isCloudinaryConfigured =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;

  static FirebaseOptions get firebaseOptions => FirebaseOptions(
        apiKey: firebaseApiKey,
        authDomain: firebaseAuthDomain.isNotEmpty
            ? firebaseAuthDomain
            : '$firebaseProjectId.firebaseapp.com',
        projectId: firebaseProjectId,
        messagingSenderId: firebaseMessagingSenderId,
        appId: firebaseAppId,
        storageBucket:
            firebaseStorageBucket.isNotEmpty ? firebaseStorageBucket : null,
      );
}
