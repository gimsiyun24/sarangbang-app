import 'package:intl/intl.dart';

/// 사랑방 주차 = **주일(일요일) 시작** 기준.
/// 카톡에 올리던 "0104 기도제목 및 신앙루틴" 의 0104 가 그 주 주일 날짜입니다.
///
/// 주차 번호는 **그 해의 첫 주일을 1주차**로 세어 매깁니다.
/// (1월 1일 기준으로 세면 id ↔ 날짜 변환이 어긋납니다)
class Week {
  final DateTime sunday; // 그 주의 주일 (자정)

  Week(DateTime anyDay) : sunday = _sundayOf(anyDay);

  /// 날짜 덧셈은 Duration 대신 DateTime 생성자로 — 서머타임이 있어도 안전
  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static DateTime _sundayOf(DateTime d) {
    // Dart weekday: 월=1 … 일=7  →  일요일이면 %7 == 0
    return _addDays(d, -(d.weekday % 7));
  }

  /// 그 해의 첫 번째 주일
  static DateTime _firstSunday(int year) {
    final jan1 = DateTime(year, 1, 1);
    return _addDays(jan1, (7 - jan1.weekday) % 7);
  }

  static Week current() => Week(DateTime.now());

  static Week fromId(String id) {
    // "2026-W35"
    final m = RegExp(r'^(\d{4})-W(\d{1,2})$').firstMatch(id);
    if (m == null) return Week.current();
    final year = int.parse(m.group(1)!);
    final n = int.parse(m.group(2)!);
    return Week(_addDays(_firstSunday(year), (n - 1) * 7));
  }

  /// "2026-W35"
  String get id {
    final first = _firstSunday(sunday.year);
    final n = (sunday.difference(first).inDays ~/ 7) + 1;
    return '${sunday.year}-W${n.toString().padLeft(2, '0')}';
  }

  DateTime get saturday => _addDays(sunday, 6);

  /// 카톡 복사 머리말에 쓰는 "0830"
  String get mmdd => DateFormat('MMdd').format(sunday);

  /// "8/30(주일) 주간"
  String get label => '${DateFormat('M/d').format(sunday)}(주일) 주간';

  /// "2026.08.30 ~ 09.05"
  String get range =>
      '${DateFormat('yyyy.MM.dd').format(sunday)} ~ ${DateFormat('MM.dd').format(saturday)}';

  bool get isCurrent => id == Week.current().id;

  Week get previous => Week(_addDays(sunday, -7));
  Week get next => Week(_addDays(sunday, 7));

  /// 최근 주차 목록 (이번 주부터 과거로)
  static List<Week> recent(int count) {
    var w = Week.current();
    final out = <Week>[];
    for (var i = 0; i < count; i++) {
      out.add(w);
      w = w.previous;
    }
    return out;
  }

  @override
  bool operator ==(Object other) => other is Week && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

String ymd(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String today() => ymd(DateTime.now());
