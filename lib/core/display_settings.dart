import 'dart:js_interop';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 글씨 크기 — 애기애타 설정 화면과 같은 세 칸.
///
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

/// 기기마다 따로 둡니다(애기애타와 같음) — 폰은 중간, 집 태블릿은 크게 같은 식으로.
const _storageKey = 'sarangbang:text-size';

@JS('localStorage')
external _Storage get _localStorage;

extension type _Storage._(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
}

/// 사생활 보호 창처럼 저장소를 못 쓰는 브라우저에서는 늘 중간으로 둡니다.
TextSize _load() {
  try {
    final saved = _localStorage.getItem(_storageKey.toJS)?.toDart;
    return TextSize.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => TextSize.normal,
    );
  } catch (_) {
    return TextSize.normal;
  }
}

class TextSizeNotifier extends StateNotifier<TextSize> {
  TextSizeNotifier() : super(_load());

  void set(TextSize next) {
    state = next;
    try {
      _localStorage.setItem(_storageKey.toJS, next.name.toJS);
    } catch (_) {}
  }
}

final textSizeProvider =
    StateNotifierProvider<TextSizeNotifier, TextSize>((ref) => TextSizeNotifier());
