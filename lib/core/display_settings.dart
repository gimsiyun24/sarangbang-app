import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_storage.dart';

/// 보기 설정 — 애기애타 설정 화면의 "글씨 크기"·"화면"과 같습니다. 기기마다 따로 둡니다.

// ─────────────────────────────────────────── 글씨 크기

/// 글씨만 키우지 않고 화면 전체를 확대·축소합니다(애기애타의 CSS zoom 과 같은 방식,
/// main.dart 의 _Zoom). 여백·아이콘도 함께 커져서 칸이 글씨에 눌리지 않습니다.
/// 대신 크게로 두면 보이는 폭이 그만큼 좁아집니다.
enum TextSize {
  small('작게', 0.9, 14),
  normal('중간', 1.0, 17),
  large('크게', 1.15, 20);

  const TextSize(this.label, this.zoom, this.previewFontSize);

  final String label;
  final double zoom;

  /// 설정 화면의 고르개에서 칸마다 그 크기로 글씨를 써서 미리 보여줄 때
  final double previewFontSize;
}

const _textSizeKey = 'sarangbang:text-size';

class TextSizeNotifier extends StateNotifier<TextSize> {
  TextSizeNotifier()
      : super(TextSize.values.firstWhere(
          (s) => s.name == deviceRead(_textSizeKey),
          orElse: () => TextSize.normal,
        ));

  void set(TextSize next) {
    state = next;
    deviceWrite(_textSizeKey, next.name);
  }
}

final textSizeProvider =
    StateNotifierProvider<TextSizeNotifier, TextSize>((ref) => TextSizeNotifier());

// ─────────────────────────────────────────── 화면 밝기

/// 아무것도 고르지 않은 상태(null)가 곧 "폰 설정 따라가기"입니다.
/// 설정 화면에는 밝게/어둡게 두 칸만 둡니다 — 애기애타와 같은 이유로, 안 고른 상태가
/// 이미 시스템이라 굳이 누를 일이 없습니다. 하나를 누르면 그때부터 이 기기에서만 그 밝기로 굳습니다.
///
/// ★ web/index.html 의 앞머리 스크립트가 같은 열쇠를 읽어 로딩 화면 색을 미리 맞춥니다.
const _themeKey = 'sarangbang:theme';

class ThemeChoiceNotifier extends StateNotifier<Brightness?> {
  ThemeChoiceNotifier()
      : super(switch (deviceRead(_themeKey)) {
          'dark' => Brightness.dark,
          'light' => Brightness.light,
          _ => null,
        });

  void set(Brightness next) {
    state = next;
    deviceWrite(_themeKey, next == Brightness.dark ? 'dark' : 'light');
  }
}

/// 이 기기에서 고른 밝기. null 이면 폰 설정을 따릅니다.
final themeChoiceProvider = StateNotifierProvider<ThemeChoiceNotifier, Brightness?>(
    (ref) => ThemeChoiceNotifier());

/// 폰의 밝기 설정 — main.dart 가 바뀔 때마다 적어 넣습니다.
final platformBrightnessProvider = StateProvider<Brightness>(
  (ref) => WidgetsBinding.instance.platformDispatcher.platformBrightness,
);

/// 지금 실제로 보이는 밝기. 설정 화면의 파란 상자는 "고른 값"이 아니라 이 값에 앉습니다 —
/// 아직 아무것도 안 고른 사람에게도 둘 중 하나에는 상자가 앉아 있고, 폰에서 다크 모드를 켜면 저절로 옮겨갑니다.
final resolvedBrightnessProvider = Provider<Brightness>(
  (ref) => ref.watch(themeChoiceProvider) ?? ref.watch(platformBrightnessProvider),
);
