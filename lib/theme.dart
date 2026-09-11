import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ── 디자인 토큰 ──────────────────────────────────────────────
/// 애기애타 10기 앱과 같은 틀(회색 바탕 + 흰 카드 + 먹색 글씨)에
/// 주 색만 뉴웨이브 로고의 파랑으로 바꿨습니다. 색은 이 파일에서만 정의합니다.
class AppColors {
  AppColors._();

  /// 뉴웨이브 로고의 파랑. 글씨·아이콘·버튼 바탕의 파랑은 전부 이 하나를 씁니다.
  static const brand = Color(0xFF2088C8);

  /// brand 를 흰색 쪽으로만 옅게 푼 단계 (애기애타 주황 램프와 같은 비율).
  /// 배경·테두리처럼 연하게 깔 자리에만 씁니다.
  static const brand50 = Color(0xFFECF5FA);
  static const brand100 = Color(0xFFD5E8F5);
  static const brand200 = Color(0xFFAAD2EA);
  static const brand300 = Color(0xFF7AB8DE);
  static const brand400 = Color(0xFF50A2D4);

  /// 화면 바탕. 흰 카드가 묻히지 않도록 흰색과 밝기 차이를 둔 아주 연한 회색.
  static const canvas = Color(0xFFECEDEE);
  static const surface = Colors.white;

  /// 바탕 위에 한 겹 더 옅게 까는 자리 — 눌린 상태, 중립 배지, 카드 안 상자
  static const fill = Color(0xFFF5F5F4);
  static const line = Color(0xFFE4E6E9);
  static const lineStrong = Color(0xFFD4D6D9);

  /// 완전한 검정 대신 살짝 붉은 기가 도는 차콜
  static const ink = Color(0xFF1C1917);
  static const inkSoft = Color(0xFF57534E);
  static const inkMuted = Color(0xFF78716C);
  static const inkFaint = Color(0xFFA8A29E);

  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEF2F2);

  /// 보조 강조 — 기도 알림·연속 기록(금), 생일(장미), 온라인 출석(보라)
  static const gold = Color(0xFFD9A03C);
  static const goldBg = Color(0xFFFDF6E6);
  static const rose = Color(0xFFC77A8C);
  static const roseBg = Color(0xFFFDF2F4);
  static const violet = Color(0xFF7C6BD6);
  static const violetBg = Color(0xFFF1EFFC);

  static const skeletonBase = Color(0xB3DEE1E5);
  static const skeletonShine = Color(0xF2F0F2F4);
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

  /// 카드 — 짧고 진한 쪽이 경계를 잡고, 길고 옅은 쪽이 띄웁니다.
  /// 색은 차가운 검정이 아니라 먹색(ink)을 풀어 씁니다.
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D1C1917),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x121C1917),
      blurRadius: 13,
      offset: Offset(0, 6),
    ),
  ];

  /// 한 단계 더 떠 있는 것 (하단 탭바, 로그인 로고)
  static const float = <BoxShadow>[
    BoxShadow(
      color: Color(0x121C1917),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x211C1917),
      blurRadius: 27,
      offset: Offset(0, 12),
    ),
  ];
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
        {Color color = AppColors.ink, double? height, double? spacing}) =>
    TextStyle(
      fontFamily: kFontFamily,
      fontFamilyFallback: kFontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing ?? -0.2,
    );

/// 앱 전역 텍스트 스타일 — 화면마다 다른 숫자를 쓰지 않도록
class AppText {
  AppText._();

  static final display = _t(24, FontWeight.w700, height: 1.3, spacing: -0.6);
  static final title = _t(22, FontWeight.w700, height: 1.3, spacing: -0.55);
  static final cardTitle = _t(16, FontWeight.w700, height: 1.35, spacing: -0.3);
  static final section = _t(17, FontWeight.w700, height: 1.3, spacing: -0.3);
  static final body = _t(15, FontWeight.w400, color: AppColors.inkSoft, height: 1.6);
  static final bodyStrong = _t(15, FontWeight.w700, height: 1.5);
  static final label = _t(15, FontWeight.w700);
  static final caption = _t(13, FontWeight.w400, color: AppColors.inkMuted, height: 1.5);
  static final micro = _t(12, FontWeight.w500, color: AppColors.inkFaint);
  static final num = _t(15, FontWeight.w700, color: AppColors.brand, spacing: -0.4);
  static final tab = _t(13, FontWeight.w500, color: AppColors.inkSoft, height: 1);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.brand,
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
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
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
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppText.title,
      iconTheme: const IconThemeData(color: AppColors.inkSoft, size: 26),
      actionsIconTheme: const IconThemeData(color: AppColors.inkSoft, size: 26),
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
        side: const BorderSide(color: AppColors.line),
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

    dividerTheme:
        const DividerThemeData(color: AppColors.line, space: 1, thickness: 1),

    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      titleTextStyle: _t(18, FontWeight.w700, height: 1.35, spacing: -0.3),
      contentTextStyle: AppText.body,
    ),

    // 애기애타 시트처럼 회색 바탕에 흰 입력칸·카드를 얹습니다.
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
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

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      elevation: 6,
      contentTextStyle: _t(14, FontWeight.w500, color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      insetPadding: const EdgeInsets.all(16),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
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
