import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// 유리판 — 애플의 Liquid Glass 를 웹앱에서 할 수 있는 만큼 흉내 낸 것입니다.
///
/// 네 가지가 겹쳐서 유리로 보입니다.
///  · 뒤를 흐리게(blur) — 뒤 내용이 비치되 글씨를 가리지 않을 만큼만
///  · 색을 살리기(saturate) — 흐리면 색이 바래는데, 진짜 유리는 뒤 색을 죽이지 않습니다
///  · 카드색을 반투명하게 한 겹 — 그 위의 글씨가 읽히도록 바탕을 잡아 줍니다
///  · 윗변의 흰 하이라이트와 둘레의 얇은 흰 테 — 빛이 위에서 떨어져 모서리에 걸린 모양.
///    유리 느낌은 사실 이 선에서 가장 많이 나옵니다.
///
/// ★ 애플 지침대로 **떠 있는 조작 요소에만** 씁니다(하단 탭바·바텀시트).
///   내용 카드까지 유리로 만들면 글씨가 뒤 내용과 섞여 읽기 힘들어집니다.
/// ★ 화면에 유리는 되도록 하나만 둡니다. 아이폰 사파리는 뒤를 흐리는 자리가 많을수록 스크롤이 버벅입니다.
/// ★ 기기에서 "대비 높이기"를 켜 두었으면 유리를 끄고 불투명하게 그립니다(애플 접근성 규칙과 같음).
class GlassSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets? padding;
  final double? height;

  /// 뒤를 흐리는 정도. 값이 커질수록 폰에서 무거워져 낮게 잡습니다.
  final double blur;
  final List<BoxShadow>? shadow;

  const GlassSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.padding,
    this.height,
    this.blur = 12,
    this.shadow,
  });

  /// 색을 진하게 살리는 행렬 (1 이면 그대로, 1.4 면 40% 더 진하게)
  static ColorFilter _saturate(double amount) {
    const r = 0.213, g = 0.715, b = 0.072;
    final s = amount;
    return ColorFilter.matrix(<double>[
      r + (1 - r) * s, g - g * s, b - b * s, 0, 0,
      r - r * s, g + (1 - g) * s, b - b * s, 0, 0,
      r - r * s, g - g * s, b + (1 - b) * s, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final plain = MediaQuery.highContrastOf(context);

    final body = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: plain
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: dark ? 0.66 : 0.68),
        borderRadius: borderRadius,
        border: plain
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: dark ? 0.14 : 0.42),
                width: 0.8,
              ),
      ),
      child: child,
    );

    return DecoratedBox(
      // 바깥 그림자는 잘라내기 밖에 둬야 유리 둘레에 남습니다.
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow ?? AppShadow.float,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: plain
            ? body
            : BackdropFilter(
                filter: ui.ImageFilter.compose(
                  outer: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  inner: _saturate(1.4),
                ),
                child: Stack(
                  children: [
                    // 크기를 정하는 것은 이 몸통입니다 — 위치를 지정한 자식만 있으면 높이를 정할 수 없습니다.
                    body,
                    // 윗변에서 아래로 사라지는 흰 하이라이트
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: (height ?? 64) * 0.55,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: dark ? 0.08 : 0.24),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
