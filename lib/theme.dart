import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ── 디자인 토큰 ──────────────────────────────────────────────
/// 파스텔 그린 (🍀 톤). 한 곳에서만 색을 정의합니다.
class AppColors {
  AppColors._();

  static const seed = Color(0xFF4CAF82);
  static const deep = Color(0xFF2E7D5B);
  static const deeper = Color(0xFF1F5C42);
  static const mint = Color(0xFFE4F3EA);
  static const mintSoft = Color(0xFFF1F8F4);

  static const bg = Color(0xFFF5F8F6);
  static const card = Colors.white;
  static const line = Color(0xFFE8EFEB);
  static const lineSoft = Color(0xFFF0F5F2);

  static const ink = Color(0xFF16241D);
  static const ink2 = Color(0xFF3D4F46);
  static const muted = Color(0xFF7C8D84);
  static const faint = Color(0xFFAFBDB5);

  static const warn = Color(0xFFDE6E52);
  static const warnBg = Color(0xFFFDEDE8);
  static const gold = Color(0xFFD9A03C);
  static const goldBg = Color(0xFFFDF6E6);
  static const rose = Color(0xFFC77A8C);
  static const roseBg = Color(0xFFFDF2F4);
  static const blue = Color(0xFF5F86C9);
  static const blueBg = Color(0xFFEDF2FC);
}

class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

class AppShadow {
  AppShadow._();

  /// 카드 — 아주 옅게, 두 겹으로 (시중 앱 느낌의 부드러운 깊이)
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A1E3A2C),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0F1E3A2C),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// 떠 있는 요소 (바텀시트 핸들, FAB 주변)
  static const raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x141E3A2C),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  /// 하단 네비게이션 바
  static const nav = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D1E3A2C),
      blurRadius: 20,
      offset: Offset(0, -4),
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

  static final display = _t(26, FontWeight.w800, height: 1.3, spacing: -0.6);
  static final title = _t(20, FontWeight.w800, height: 1.3, spacing: -0.5);
  static final cardTitle = _t(16, FontWeight.w800, height: 1.35, spacing: -0.4);
  static final section = _t(14.5, FontWeight.w800, height: 1.3, spacing: -0.3);
  static final body = _t(14, FontWeight.w500, color: AppColors.ink2, height: 1.6);
  static final bodyStrong = _t(14, FontWeight.w700, height: 1.55);
  static final label = _t(13, FontWeight.w700, color: AppColors.ink2);
  static final caption = _t(12, FontWeight.w500, color: AppColors.muted, height: 1.5);
  static final micro = _t(11, FontWeight.w600, color: AppColors.faint);
  static final num = _t(15, FontWeight.w800, color: AppColors.deep, spacing: -0.4);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: Brightness.light,
  ).copyWith(
    surface: AppColors.bg,
    primary: AppColors.deep,
    error: AppColors.warn,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: kFontFamily,
    fontFamilyFallback: kFontFallback,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 20,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppText.title,
      iconTheme: const IconThemeData(color: AppColors.ink2, size: 22),
    ),

    // 카드는 SoftCard 위젯에서 그림자를 직접 그립니다.
    cardTheme: CardThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: AppColors.mint,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelStyle: _t(12, FontWeight.w700, color: AppColors.deep),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill)),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      hintStyle: _t(14, FontWeight.w500, color: AppColors.faint),
      labelStyle: _t(13.5, FontWeight.w600, color: AppColors.muted),
      floatingLabelStyle: _t(13, FontWeight.w700, color: AppColors.deep),
      border: _inputBorder(AppColors.line),
      enabledBorder: _inputBorder(AppColors.line),
      focusedBorder: _inputBorder(AppColors.seed, width: 1.5),
      errorBorder: _inputBorder(AppColors.warn),
      focusedErrorBorder: _inputBorder(AppColors.warn, width: 1.5),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.deep,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.mint,
        disabledForegroundColor: AppColors.muted,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: _t(15, FontWeight.w700, color: Colors.white),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deep,
        backgroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        side: const BorderSide(color: AppColors.line),
        textStyle: _t(14.5, FontWeight.w700, color: AppColors.deep),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.deep,
        textStyle: _t(13, FontWeight.w700, color: AppColors.deep),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.deep,
      foregroundColor: Colors.white,
      elevation: 3,
      focusElevation: 3,
      hoverElevation: 5,
      highlightElevation: 3,
      extendedTextStyle: _t(14.5, FontWeight.w700, color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill)),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.mint,
      elevation: 0,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: 23,
            color: s.contains(WidgetState.selected)
                ? AppColors.deep
                : AppColors.faint,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => _t(
            11,
            s.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: s.contains(WidgetState.selected)
                ? AppColors.deep
                : AppColors.muted,
          )),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.deep,
      unselectedLabelColor: AppColors.muted,
      labelStyle: _t(14, FontWeight.w800, color: AppColors.deep),
      unselectedLabelStyle: _t(14, FontWeight.w600, color: AppColors.muted),
      indicatorColor: AppColors.seed,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),

    dividerTheme: const DividerThemeData(
        color: AppColors.lineSoft, space: 1, thickness: 1),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      titleTextStyle: AppText.cardTitle,
      contentTextStyle: AppText.body,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: _t(13.5, FontWeight.w600),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      elevation: 6,
      contentTextStyle: _t(13.5, FontWeight.w600, color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm)),
      insetPadding: const EdgeInsets.all(16),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.seed,
      linearTrackColor: AppColors.lineSoft,
      circularTrackColor: Colors.transparent,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? Colors.white : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.seed
              : const Color(0xFFDCE5E0)),
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
