import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ── 디자인 토큰 ──────────────────────────────────────────────
/// 애기애타 10기 앱과 같은 틀(회색 바탕 + 흰 카드 + 먹색 글씨)에
/// 주 색만 뉴웨이브 로고의 파랑으로 바꿨습니다. 색은 이 파일에서만 정의합니다.
///
/// 밝은 화면·어두운 화면 두 벌의 값을 두고, 화면을 그리는 코드는 AppColors.canvas 처럼
/// **역할 이름만** 씁니다. 설정에서 밝기를 바꾸면 AppColors.use() 로 벌을 갈아끼우고
/// 앱 전체를 다시 그립니다(main.dart). 어두운 화면 값은 애기애타 globals.css 와 같습니다.
class AppPalette {
  final Color brand50, brand100, brand200;
  final Color canvas, surface, fill, line, lineStrong;
  final Color ink, inkSoft, inkMuted, inkFaint;
  final Color danger, dangerBg;
  final Color gold, goldBg, rose, roseBg, violet, violetBg;
  final Color skeletonBase, skeletonShine;
  final List<BoxShadow> cardShadow, floatShadow;

  const AppPalette({
    required this.brand50,
    required this.brand100,
    required this.brand200,
    required this.canvas,
    required this.surface,
    required this.fill,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.inkFaint,
    required this.danger,
    required this.dangerBg,
    required this.gold,
    required this.goldBg,
    required this.rose,
    required this.roseBg,
    required this.violet,
    required this.violetBg,
    required this.skeletonBase,
    required this.skeletonShine,
    required this.cardShadow,
    required this.floatShadow,
  });
}

const _light = AppPalette(
  // brand 를 흰색 쪽으로만 옅게 푼 단계 (애기애타 주황 램프와 같은 비율). 배경·테두리에만.
  brand50: Color(0xFFECF5FA),
  brand100: Color(0xFFD5E8F5),
  brand200: Color(0xFFAAD2EA),
  // 화면 바탕. 흰 카드가 묻히지 않도록 흰색과 밝기 차이를 둔 아주 연한 회색.
  canvas: Color(0xFFECEDEE),
  surface: Color(0xFFFFFFFF),
  // 바탕 위에 한 겹 더 옅게 까는 자리 — 눌린 상태, 중립 배지, 카드 안 상자
  fill: Color(0xFFF5F5F4),
  line: Color(0xFFE4E6E9),
  lineStrong: Color(0xFFD4D6D9),
  // 완전한 검정 대신 살짝 붉은 기가 도는 차콜
  ink: Color(0xFF1C1917),
  inkSoft: Color(0xFF57534E),
  inkMuted: Color(0xFF78716C),
  inkFaint: Color(0xFFA8A29E),
  danger: Color(0xFFDC2626),
  dangerBg: Color(0xFFFEF2F2),
  // 보조 강조 — 기도 알림·연속 기록(금), 생일(장미), 온라인 출석(보라)
  gold: Color(0xFFD9A03C),
  goldBg: Color(0xFFFDF6E6),
  rose: Color(0xFFC77A8C),
  roseBg: Color(0xFFFDF2F4),
  violet: Color(0xFF7C6BD6),
  violetBg: Color(0xFFF1EFFC),
  skeletonBase: Color(0xB3DEE1E5),
  skeletonShine: Color(0xF2F0F2F4),
  // 카드 — 짧고 진한 쪽이 경계를 잡고, 길고 옅은 쪽이 띄웁니다. 색은 먹색(ink)을 풀어 씁니다.
  cardShadow: [
    BoxShadow(color: Color(0x0D1C1917), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x121C1917), blurRadius: 13, offset: Offset(0, 6)),
  ],
  // 한 단계 더 떠 있는 것 (하단 탭바, 로그인 로고)
  floatShadow: [
    BoxShadow(color: Color(0x121C1917), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x211C1917), blurRadius: 27, offset: Offset(0, 12)),
  ],
);

const _dark = AppPalette(
  // 연한 파랑 자리(배지·선택 칸)는 그대로 두면 눈부신 판이 되어, 파랑을 어둡게 눌렀습니다.
  brand50: Color(0xFF132634),
  brand100: Color(0xFF17314A),
  brand200: Color(0xFF1F4766),
  canvas: Color(0xFF121315),
  surface: Color(0xFF1D1F22),
  fill: Color(0xFF2A2D31),
  line: Color(0xFF313438),
  lineStrong: Color(0xFF3E4247),
  ink: Color(0xFFF0F1F2),
  inkSoft: Color(0xFFC4C7CB),
  inkMuted: Color(0xFF9AA0A6),
  // 옅은 글씨는 그대로 뒤집으면 읽히지 않아 카드 바탕 대비 4.2:1 까지 올렸습니다.
  inkFaint: Color(0xFF7B8189),
  danger: Color(0xFFF87171),
  dangerBg: Color(0xFF3A1F1F),
  gold: Color(0xFFE3B35A),
  goldBg: Color(0xFF33291A),
  rose: Color(0xFFD98FA0),
  roseBg: Color(0xFF3A2329),
  violet: Color(0xFF9A8CF0),
  violetBg: Color(0xFF262240),
  skeletonBase: Color(0x0DFFFFFF),
  skeletonShine: Color(0x1CFFFFFF),
  // 어두운 화면에서는 검은 그림자가 안 보여, 카드는 바탕보다 밝은 surface 로 떠오르고
  // 그림자는 경계를 잡는 정도로만 남깁니다.
  cardShadow: [
    BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x47000000), blurRadius: 13, offset: Offset(0, 6)),
  ],
  floatShadow: [
    BoxShadow(color: Color(0x73000000), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x66000000), blurRadius: 27, offset: Offset(0, 12)),
  ],
);

class AppColors {
  AppColors._();

  static AppPalette _p = _light;

  /// 지금 어두운 화면인지
  static bool get isDark => identical(_p, _dark);

  /// 밝은/어두운 벌을 갈아끼웁니다. 부른 뒤에는 앱 전체를 다시 그려야 반영됩니다(main.dart).
  static void use(Brightness brightness) =>
      _p = brightness == Brightness.dark ? _dark : _light;

  /// 뉴웨이브 로고의 파랑. 글씨·아이콘·버튼 바탕의 파랑은 전부 이 하나를 씁니다.
  /// 어두운 화면에서도 같은 색입니다(어두운 바탕에서 오히려 제 색을 냅니다).
  static const brand = Color(0xFF2088C8);
  static const brand300 = Color(0xFF7AB8DE);
  static const brand400 = Color(0xFF50A2D4);

  static Color get brand50 => _p.brand50;
  static Color get brand100 => _p.brand100;
  static Color get brand200 => _p.brand200;

  static Color get canvas => _p.canvas;
  static Color get surface => _p.surface;
  static Color get fill => _p.fill;
  static Color get line => _p.line;
  static Color get lineStrong => _p.lineStrong;

  static Color get ink => _p.ink;
  static Color get inkSoft => _p.inkSoft;
  static Color get inkMuted => _p.inkMuted;
  static Color get inkFaint => _p.inkFaint;

  static Color get danger => _p.danger;
  static Color get dangerBg => _p.dangerBg;

  static Color get gold => _p.gold;
  static Color get goldBg => _p.goldBg;
  static Color get rose => _p.rose;
  static Color get roseBg => _p.roseBg;
  static Color get violet => _p.violet;
  static Color get violetBg => _p.violetBg;

  static Color get skeletonBase => _p.skeletonBase;
  static Color get skeletonShine => _p.skeletonShine;
}

class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const pill = 999.0;
}

class AppShadow {
  AppShadow._();

  /// 카드
  static List<BoxShadow> get card => AppColors._p.cardShadow;

  /// 한 단계 더 떠 있는 것 (하단 탭바, 로그인 로고)
  static List<BoxShadow> get float => AppColors._p.floatShadow;
}

/// pubspec.yaml 에 번들한 폰트 (assets/fonts/Pretendard-*.otf)
const kFontFamily = 'Pretendard';
const kFontFallback = <String>[
  'Apple SD Gothic Neo',
  'Malgun Gothic',
  'sans-serif',
];

/// 한글은 자간을 살짝 좁혀야 정돈돼 보입니다.
TextStyle _t(double size, FontWeight weight,
        {Color? color, double? height, double? spacing}) =>
    TextStyle(
      fontFamily: kFontFamily,
      fontFamilyFallback: kFontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.ink,
      height: height,
      letterSpacing: spacing ?? -0.2,
    );

/// 앱 전역 텍스트 스타일 — 화면마다 다른 숫자를 쓰지 않도록.
/// 밝기에 따라 글씨색이 바뀌므로 부를 때마다 지금 벌의 색으로 만듭니다.
class AppText {
  AppText._();

  static TextStyle get display => _t(24, FontWeight.w700, height: 1.3, spacing: -0.6);
  static TextStyle get title => _t(22, FontWeight.w700, height: 1.3, spacing: -0.55);
  static TextStyle get cardTitle => _t(16, FontWeight.w700, height: 1.35, spacing: -0.3);
  static TextStyle get section => _t(17, FontWeight.w700, height: 1.3, spacing: -0.3);
  static TextStyle get body => _t(15, FontWeight.w400, color: AppColors.inkSoft, height: 1.6);
  static TextStyle get bodyStrong => _t(15, FontWeight.w700, height: 1.5);
  static TextStyle get label => _t(15, FontWeight.w700);
  static TextStyle get caption => _t(13, FontWeight.w400, color: AppColors.inkMuted, height: 1.5);
  static TextStyle get micro => _t(12, FontWeight.w500, color: AppColors.inkFaint);
  static TextStyle get num => _t(15, FontWeight.w700, color: AppColors.brand, spacing: -0.4);
  static TextStyle get tab => _t(13, FontWeight.w500, color: AppColors.inkSoft, height: 1);
}

ThemeData buildTheme() {
  final dark = AppColors.isDark;
  final brightness = dark ? Brightness.dark : Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.brand,
    onPrimary: Colors.white,
    error: AppColors.danger,
    surface: AppColors.canvas,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkMuted,
    outline: AppColors.line,
    outlineVariant: AppColors.line,
    surfaceTint: Colors.transparent,
    // 날짜 고르기 같은 머티리얼 창이 파랗게 물들지 않도록 중립색으로
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.fill,
    surfaceContainer: AppColors.canvas,
    surfaceContainerHigh: AppColors.canvas,
    surfaceContainerHighest: AppColors.line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    canvasColor: AppColors.canvas,
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFallback,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      titleTextStyle: AppText.title,
      iconTheme: IconThemeData(color: AppColors.inkSoft, size: 26),
      actionsIconTheme: IconThemeData(color: AppColors.inkSoft, size: 26),
    ),

    // 카드는 SoftCard 위젯에서 그림자를 직접 그립니다.
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelStyle: _t(13, FontWeight.w700, color: AppColors.inkSoft),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: _t(15, FontWeight.w400, color: AppColors.inkFaint),
      labelStyle: _t(14, FontWeight.w500, color: AppColors.inkMuted),
      floatingLabelStyle: _t(13, FontWeight.w700, color: AppColors.brand),
      border: _inputBorder(AppColors.line),
      enabledBorder: _inputBorder(AppColors.line),
      focusedBorder: _inputBorder(AppColors.brand300, width: 1.5),
      errorBorder: _inputBorder(AppColors.danger),
      focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.5),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.brand200,
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: _t(16, FontWeight.w700, color: Colors.white),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brand,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        side: BorderSide(color: AppColors.line),
        textStyle: _t(15, FontWeight.w700, color: AppColors.brand),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        textStyle: _t(14, FontWeight.w700, color: AppColors.brand),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.brand,
      foregroundColor: Colors.white,
      elevation: 3,
      focusElevation: 3,
      hoverElevation: 5,
      highlightElevation: 3,
      extendedTextStyle: _t(15, FontWeight.w700, color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill)),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.brand,
      unselectedLabelColor: AppColors.inkMuted,
      labelStyle: _t(15, FontWeight.w700, color: AppColors.brand),
      unselectedLabelStyle: _t(15, FontWeight.w500, color: AppColors.inkMuted),
      indicatorColor: AppColors.brand,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),

    dividerTheme: DividerThemeData(color: AppColors.line, space: 1, thickness: 1),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      titleTextStyle: _t(18, FontWeight.w700, height: 1.35, spacing: -0.3),
      contentTextStyle: AppText.body,
    ),

    // 애기애타 시트처럼 바탕색 위에 카드색 입력칸·카드를 얹습니다.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: _t(14, FontWeight.w500),
    ),

    // 알림 막대는 늘 반대 밝기로 — 밝은 화면에서는 먹색, 어두운 화면에서는 밝은 회색
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? AppColors.fill : AppColors.ink,
      elevation: 6,
      contentTextStyle:
          _t(14, FontWeight.w500, color: dark ? AppColors.ink : Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      insetPadding: const EdgeInsets.all(16),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.brand,
      linearTrackColor: AppColors.line,
      circularTrackColor: Colors.transparent,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.brand
              : AppColors.lineStrong),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),

    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
