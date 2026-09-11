import 'dart:js_interop';

/// 이 기기(브라우저)에만 남기는 값 — 글씨 크기·화면 밝기·알림 켬/끔.
///
/// 애기애타 앱처럼 기기마다 따로 둡니다. 폰은 중간, 집 태블릿은 크게 같은 식으로요.
/// 사생활 보호 창처럼 저장소를 못 쓰는 브라우저에서는 조용히 넘어가고, 읽으면 null 입니다.

@JS('localStorage')
external _Storage get _localStorage;

extension type _Storage._(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
  external void removeItem(JSString key);
}

String? deviceRead(String key) {
  try {
    return _localStorage.getItem(key.toJS)?.toDart;
  } catch (_) {
    return null;
  }
}

/// value 가 null 이면 지웁니다.
void deviceWrite(String key, String? value) {
  try {
    if (value == null) {
      _localStorage.removeItem(key.toJS);
    } else {
      _localStorage.setItem(key.toJS, value.toJS);
    }
  } catch (_) {}
}
