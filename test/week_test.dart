import 'package:flutter_test/flutter_test.dart';
import 'package:sarangbang_app/core/week.dart';

void main() {
  group('Week — 주일 시작 기준', () {
    test('일요일은 그 자신이 주 시작', () {
      final w = Week(DateTime(2026, 8, 30)); // 일요일
      expect(w.sunday, DateTime(2026, 8, 30));
    });

    test('주중 날짜는 직전 주일로 묶인다', () {
      for (final d in [
        DateTime(2026, 8, 31), // 월
        DateTime(2026, 9, 2), // 수
        DateTime(2026, 9, 5), // 토
      ]) {
        expect(Week(d).sunday, DateTime(2026, 8, 30));
      }
    });

    test('기획서의 2026-W35 와 일치', () {
      expect(Week(DateTime(2026, 8, 30)).id, '2026-W35');
    });

    test('카톡 머리말 MMDD', () {
      expect(Week(DateTime(2026, 1, 4)).mmdd, '0104');
      expect(Week(DateTime(2026, 8, 30)).mmdd, '0830');
    });

    test('첫 주일이 1주차', () {
      expect(Week(DateTime(2026, 1, 4)).id, '2026-W01');
      // 1/1(목)~1/3(토) 는 아직 2025년 마지막 주에 속합니다
      expect(Week(DateTime(2026, 1, 2)).sunday, DateTime(2025, 12, 28));
    });

    test('id → Week 왕복 (연말·연초 포함 3년치)', () {
      var d = DateTime(2025, 1, 1);
      while (d.isBefore(DateTime(2028, 1, 1))) {
        final w = Week(d);
        expect(Week.fromId(w.id).id, w.id, reason: '$d → ${w.id}');
        expect(Week.fromId(w.id).sunday, w.sunday, reason: '$d');
        d = DateTime(d.year, d.month, d.day + 1);
      }
    });

    test('previous/next 는 7일 간격', () {
      final w = Week(DateTime(2026, 8, 30));
      expect(w.previous.sunday, DateTime(2026, 8, 23));
      expect(w.next.sunday, DateTime(2026, 9, 6));
    });
  });
}
