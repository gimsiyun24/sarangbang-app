import '../../core/week.dart';
import '../../models/models.dart';

/// 사랑방장이 매주 손으로 타이핑하던 그 포맷 그대로 만들어 줍니다.
///
///   0830 기도제목 및 신앙루틴
///
///   💚서륜
///   기도제목: ...
///   신앙루틴: ...
///
/// "나만 보기" 항목은 절대 들어가지 않습니다.
String buildKakaoText({
  required Week week,
  required List<PrayerEntry> entries,
  required Map<String, Member> members,
}) {
  final buf = StringBuffer()
    ..writeln('${week.mmdd} 기도제목 및 신앙루틴')
    ..writeln();

  final sorted = [...entries]..sort((a, b) =>
      (a.updatedAt ?? DateTime(2100)).compareTo(b.updatedAt ?? DateTime(2100)));

  var wrote = 0;
  for (final e in sorted) {
    final publicTopics =
        e.topics.where((t) => !t.isPrivate && t.text.trim().isNotEmpty).toList();
    final routines = e.routines.where((r) => r.trim().isNotEmpty).toList();
    if (publicTopics.isEmpty && routines.isEmpty) continue;

    final name = members[e.uid]?.shortName ?? '이름없음';
    buf.writeln('💚$name');
    buf.writeln('기도제목: ${publicTopics.map((t) => t.text.trim()).join(', ')}');
    buf.writeln('신앙루틴: ${routines.join(', ')}');
    buf.writeln();
    wrote++;
  }

  if (wrote == 0) {
    return '${week.mmdd} 기도제목 및 신앙루틴\n\n(아직 올라온 내용이 없어요)';
  }
  return buf.toString().trimRight();
}

/// 아직 안 낸 사람 콕 찌르기용 문구
String buildNudgeText({
  required Week week,
  required List<Member> notSubmitted,
}) {
  if (notSubmitted.isEmpty) return '${week.mmdd} 기도제목 — 전원 제출 완료했어요! 🎉';
  final names = notSubmitted.map((m) => m.shortName).join(', ');
  return '${week.mmdd} 기도제목 및 신앙루틴 아직 안 올리신 분들이에요 🙏\n$names\n\n'
      '앱에서 바로 쓸 수 있어요!';
}
