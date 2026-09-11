import 'package:flutter/widgets.dart';

import '../theme.dart';

/// 아이콘 한 조각 — SVG path 의 d 문자열 하나와 칠하는 방법.
/// (원·사각형도 app_icons.dart 를 만들 때 path 로 바꿔 두었습니다.)
class AppIconShape {
  final String d;
  final bool stroke;
  final bool fill;

  /// 정해진 색으로 칠할 때만 (구글 로고). 없으면 아이콘 색을 따릅니다.
  final int? color;
  final bool roundCap;
  final bool roundJoin;

  const AppIconShape(
    this.d, {
    this.stroke = false,
    this.fill = false,
    this.color,
    this.roundCap = false,
    this.roundJoin = false,
  });
}

/// 24 격자에 그린 아이콘 하나. [filled] 는 하단 탭에서 고른 탭처럼 속을 채운 모양입니다.
class AppIconData {
  final double strokeWidth;
  final List<AppIconShape> outline;
  final List<AppIconShape>? filled;

  const AppIconData({
    required this.strokeWidth,
    required this.outline,
    this.filled,
  });
}

/// 애기애타 앱의 인라인 SVG 아이콘과 같은 방식으로 그리는 아이콘.
///
/// 머티리얼 [Icon] 자리에 그대로 넣을 수 있도록 크기·색을 안 주면 [IconTheme] 을 따릅니다
/// (버튼 안에서는 버튼 글씨색을 따라갑니다). 선 굵기는 24 격자 기준이라 크기에 맞춰 함께 줄고 늡니다.
class AppIcon extends StatelessWidget {
  final AppIconData icon;
  final double? size;
  final Color? color;

  /// 채운 모양이 있으면 그것을 그립니다.
  final bool filled;

  const AppIcon(this.icon, {super.key, this.size, this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 24;
    var tint = color ?? theme.color ?? AppColors.inkSoft;
    final opacity = theme.opacity;
    if (color == null && opacity != null && opacity < 1) {
      tint = tint.withValues(alpha: tint.a * opacity);
    }
    final shapes = filled ? (icon.filled ?? icon.outline) : icon.outline;

    return ExcludeSemantics(
      child: SizedBox(
        width: side,
        height: side,
        child: CustomPaint(
          painter: _AppIconPainter(shapes, icon.strokeWidth, tint),
        ),
      ),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  final List<AppIconShape> shapes;
  final double strokeWidth;
  final Color color;

  _AppIconPainter(this.shapes, this.strokeWidth, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    for (final shape in shapes) {
      final path = _SvgPath.parse(shape.d);
      if (shape.fill) {
        canvas.drawPath(
          path,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill
            ..color = shape.color == null ? color : Color(shape.color!),
        );
      }
      if (shape.stroke && strokeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = shape.roundCap ? StrokeCap.round : StrokeCap.butt
            ..strokeJoin = shape.roundJoin ? StrokeJoin.round : StrokeJoin.miter
            ..color = color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AppIconPainter old) =>
      old.shapes != shapes || old.strokeWidth != strokeWidth || old.color != color;
}

/// SVG path 의 d 문자열을 Flutter [Path] 로 바꿉니다. 한 번 읽은 것은 기억해 둡니다.
/// M L H V C S Q T A Z (대소문자 모두)와 "a.8.8 0 0 1-.8.8" 같은 줄여 쓴 숫자를 읽습니다.
class _SvgPath {
  static final _cache = <String, Path>{};
  static final _token = RegExp(
      r'[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?');

  static Path parse(String d) => _cache.putIfAbsent(d, () => _build(d));

  static Path _build(String d) {
    final tokens = _token.allMatches(d).map((m) => m.group(0)!).toList();
    final path = Path();
    var i = 0;
    var cmd = '';
    var x = 0.0, y = 0.0; // 지금 점
    var sx = 0.0, sy = 0.0; // 이 조각의 시작점 (Z 로 돌아갈 곳)
    double? cx, cy; // 직전 C/S 또는 Q/T 의 조절점 (S·T 가 반사해서 씁니다)
    var lastCmd = '';

    bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
    double n() => double.parse(tokens[i++]);

    while (i < tokens.length) {
      if (isCmd(tokens[i])) {
        cmd = tokens[i++];
      } else if (cmd == 'M') {
        cmd = 'L'; // M 뒤에 이어진 좌표는 L
      } else if (cmd == 'm') {
        cmd = 'l';
      }
      final rel = cmd == cmd.toLowerCase();
      final ox = rel ? x : 0.0, oy = rel ? y : 0.0;

      switch (cmd.toUpperCase()) {
        case 'M':
          x = ox + n();
          y = oy + n();
          path.moveTo(x, y);
          sx = x;
          sy = y;
          cx = cy = null;
        case 'L':
          x = ox + n();
          y = oy + n();
          path.lineTo(x, y);
          cx = cy = null;
        case 'H':
          x = (rel ? x : 0) + n();
          path.lineTo(x, y);
          cx = cy = null;
        case 'V':
          y = (rel ? y : 0) + n();
          path.lineTo(x, y);
          cx = cy = null;
        case 'C':
          final x1 = ox + n(), y1 = oy + n();
          final x2 = ox + n(), y2 = oy + n();
          x = ox + n();
          y = oy + n();
          path.cubicTo(x1, y1, x2, y2, x, y);
          cx = x2;
          cy = y2;
        case 'S':
          final reflect = lastCmd == 'C' || lastCmd == 'S';
          final x1 = reflect && cx != null ? 2 * x - cx : x;
          final y1 = reflect && cy != null ? 2 * y - cy : y;
          final x2 = ox + n(), y2 = oy + n();
          x = ox + n();
          y = oy + n();
          path.cubicTo(x1, y1, x2, y2, x, y);
          cx = x2;
          cy = y2;
        case 'Q':
          final x1 = ox + n(), y1 = oy + n();
          x = ox + n();
          y = oy + n();
          path.quadraticBezierTo(x1, y1, x, y);
          cx = x1;
          cy = y1;
        case 'T':
          final reflect = lastCmd == 'Q' || lastCmd == 'T';
          final x1 = reflect && cx != null ? 2 * x - cx : x;
          final y1 = reflect && cy != null ? 2 * y - cy : y;
          x = ox + n();
          y = oy + n();
          path.quadraticBezierTo(x1, y1, x, y);
          cx = x1;
          cy = y1;
        case 'A':
          final rx = n(), ry = n(), rotation = n();
          final largeArc = n() != 0, sweep = n() != 0;
          x = ox + n();
          y = oy + n();
          // SVG 의 sweep-flag 1 이 Flutter 의 clockwise: true 와 같습니다 (y 가 아래로 커지는 좌표).
          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: rotation,
            largeArc: largeArc,
            clockwise: sweep,
          );
          cx = cy = null;
        case 'Z':
          path.close();
          x = sx;
          y = sy;
          cx = cy = null;
      }
      lastCmd = cmd.toUpperCase();
    }
    return path;
  }
}
