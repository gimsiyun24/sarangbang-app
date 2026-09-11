import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sarangbang_app/widgets/app_icon.dart';
import 'package:sarangbang_app/widgets/app_icons.dart';

/// 아이콘은 SVG path 문자열을 그릴 때 읽기 때문에, 좌표를 잘못 적으면 화면에 뜰 때에야 터집니다.
/// 모든 아이콘을 속 빈 모양·채운 모양으로 한 번씩 그려서 미리 잡습니다.
void main() {
  testWidgets('모든 아이콘이 오류 없이 그려진다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [
            for (final icon in AppIcons.all.values) ...[
              AppIcon(icon, size: 24, color: Colors.black),
              AppIcon(icon, size: 13, filled: true),
            ],
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AppIcon), findsNWidgets(AppIcons.all.length * 2));
  });

  test('하단 탭 아이콘에는 채운 모양이 있다', () {
    for (final icon in [
      AppIcons.home,
      AppIcons.heartHand,
      AppIcons.chat,
      AppIcons.calendar,
      AppIcons.grid,
    ]) {
      expect(icon.filled, isNotNull);
    }
  });
}
