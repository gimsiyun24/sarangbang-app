// 사랑방 앱 아이콘 모음 — 애기애타 10기 앱(src/components/icons.tsx)과 같은 규칙으로 그렸습니다.
//  · 24 격자, 기본 선 굵기 1.8, 열린 선은 끝이 둥글고 닫힌 도형은 모서리가 둥급니다.
//  · 하단 탭 아이콘에는 고른 탭용으로 속을 채운 모양(filled)이 따로 있습니다.
//  · 원·사각형은 SVG path(d)로 바꿔 적었습니다. 좌표를 고칠 때는 이 파일을 직접 고치면 됩니다.
// 그리는 쪽은 app_icon.dart 의 AppIcon 입니다.

import 'app_icon.dart';

class AppIcons {
  AppIcons._();

  /// 애기애타 icons.tsx 에서 옮김
  static const home = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.5 10.4 12 4l8.5 6.4V19a1.5 1.5 0 0 1-1.5 1.5h-3.5V15h-7v5.5H5A1.5 1.5 0 0 1 3.5 19v-8.6Z', stroke: true, roundJoin: true),
    ],
    filled: [
      AppIconShape('M3.5 10.4 12 4l8.5 6.4V19a1.5 1.5 0 0 1-1.5 1.5h-3.5V15h-7v5.5H5A1.5 1.5 0 0 1 3.5 19v-8.6Z', stroke: true, fill: true, roundJoin: true),
    ],
  );

  /// 기도 탭 — 모은 두 손 위의 하트
  static const heartHand = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M12 12.6c-2.9-1.8-4.7-3.7-4.7-5.9A2.4 2.4 0 0 1 9.7 4.3c.95 0 1.8.5 2.3 1.25.5-.75 1.35-1.25 2.3-1.25a2.4 2.4 0 0 1 2.4 2.4c0 2.2-1.8 4.1-4.7 5.9Z', stroke: true, roundJoin: true),
      AppIconShape('M3.8 14.4c1.5 3.7 4.5 5.8 8.2 5.8s6.7-2.1 8.2-5.8', stroke: true, roundCap: true),
    ],
    filled: [
      AppIconShape('M12 12.6c-2.9-1.8-4.7-3.7-4.7-5.9A2.4 2.4 0 0 1 9.7 4.3c.95 0 1.8.5 2.3 1.25.5-.75 1.35-1.25 2.3-1.25a2.4 2.4 0 0 1 2.4 2.4c0 2.2-1.8 4.1-4.7 5.9Z', stroke: true, fill: true, roundJoin: true),
      AppIconShape('M3.8 14.4c1.5 3.7 4.5 5.8 8.2 5.8s6.7-2.1 8.2-5.8', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const chat = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M4 6.4A1.9 1.9 0 0 1 5.9 4.5h12.2A1.9 1.9 0 0 1 20 6.4v7.9a1.9 1.9 0 0 1-1.9 1.9H9.3L5 19.8v-3.6h-.1A.9.9 0 0 1 4 15.3V6.4Z', stroke: true, roundJoin: true),
    ],
    filled: [
      AppIconShape('M4 6.4A1.9 1.9 0 0 1 5.9 4.5h12.2A1.9 1.9 0 0 1 20 6.4v7.9a1.9 1.9 0 0 1-1.9 1.9H9.3L5 19.8v-3.6h-.1A.9.9 0 0 1 4 15.3V6.4Z', stroke: true, fill: true, roundJoin: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const calendar = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M6 5.4H18A2.4 2.4 0 0 1 20.4 7.8V18A2.4 2.4 0 0 1 18 20.4H6A2.4 2.4 0 0 1 3.6 18V7.8A2.4 2.4 0 0 1 6 5.4Z', stroke: true),
      AppIconShape('M3.6 10h16.8M8.4 3.6v3.4M15.6 3.6v3.4', stroke: true, roundCap: true),
    ],
    filled: [
      AppIconShape('M3.6 9V7.8A2.4 2.4 0 0 1 6 5.4h12a2.4 2.4 0 0 1 2.4 2.4V9H3.6Z', stroke: true, fill: true, roundJoin: true),
      AppIconShape('M3.6 11.4h16.8v6.6a2.4 2.4 0 0 1-2.4 2.4H6a2.4 2.4 0 0 1-2.4-2.4v-6.6Z', stroke: true, fill: true, roundJoin: true),
      AppIconShape('M8.4 3.2v3.4M15.6 3.2v3.4', stroke: true, roundCap: true),
    ],
  );

  /// 더보기 탭
  static const grid = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M5.8 4H9A1.8 1.8 0 0 1 10.8 5.8V9A1.8 1.8 0 0 1 9 10.8H5.8A1.8 1.8 0 0 1 4 9V5.8A1.8 1.8 0 0 1 5.8 4Z', stroke: true),
      AppIconShape('M15 4H18.2A1.8 1.8 0 0 1 20 5.8V9A1.8 1.8 0 0 1 18.2 10.8H15A1.8 1.8 0 0 1 13.2 9V5.8A1.8 1.8 0 0 1 15 4Z', stroke: true),
      AppIconShape('M5.8 13.2H9A1.8 1.8 0 0 1 10.8 15V18.2A1.8 1.8 0 0 1 9 20H5.8A1.8 1.8 0 0 1 4 18.2V15A1.8 1.8 0 0 1 5.8 13.2Z', stroke: true),
      AppIconShape('M15 13.2H18.2A1.8 1.8 0 0 1 20 15V18.2A1.8 1.8 0 0 1 18.2 20H15A1.8 1.8 0 0 1 13.2 18.2V15A1.8 1.8 0 0 1 15 13.2Z', stroke: true),
    ],
    filled: [
      AppIconShape('M5.8 4H9A1.8 1.8 0 0 1 10.8 5.8V9A1.8 1.8 0 0 1 9 10.8H5.8A1.8 1.8 0 0 1 4 9V5.8A1.8 1.8 0 0 1 5.8 4Z', stroke: true, fill: true),
      AppIconShape('M15 4H18.2A1.8 1.8 0 0 1 20 5.8V9A1.8 1.8 0 0 1 18.2 10.8H15A1.8 1.8 0 0 1 13.2 9V5.8A1.8 1.8 0 0 1 15 4Z', stroke: true, fill: true),
      AppIconShape('M5.8 13.2H9A1.8 1.8 0 0 1 10.8 15V18.2A1.8 1.8 0 0 1 9 20H5.8A1.8 1.8 0 0 1 4 18.2V15A1.8 1.8 0 0 1 5.8 13.2Z', stroke: true, fill: true),
      AppIconShape('M15 13.2H18.2A1.8 1.8 0 0 1 20 15V18.2A1.8 1.8 0 0 1 18.2 20H15A1.8 1.8 0 0 1 13.2 18.2V15A1.8 1.8 0 0 1 15 13.2Z', stroke: true, fill: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const users = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M6.2 8A3.3 3.3 0 1 0 12.8 8A3.3 3.3 0 1 0 6.2 8Z', stroke: true),
      AppIconShape('M3.5 19.2c0-3 2.7-4.8 6-4.8s6 1.8 6 4.8', stroke: true, roundCap: true),
      AppIconShape('M16.2 5.4a3 3 0 0 1 0 5.5M17.6 14.6c2 .6 3.4 2 3.4 4', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const peopleCount = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M5.4 9.4A2.6 2.6 0 1 0 10.6 9.4A2.6 2.6 0 1 0 5.4 9.4Z', stroke: true),
      AppIconShape('M13.4 9.4A2.6 2.6 0 1 0 18.6 9.4A2.6 2.6 0 1 0 13.4 9.4Z', stroke: true),
      AppIconShape('M3.4 18.4c0-2.3 2-3.7 4.6-3.7s4.6 1.4 4.6 3.7M13.6 15c2.9-.5 7 .6 7 3.4', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const person = AppIconData(
    strokeWidth: 1.9,
    outline: [
      AppIconShape('M7.9 7.44A4.1 4.1 0 1 0 16.1 7.44A4.1 4.1 0 1 0 7.9 7.44Z', stroke: true),
      AppIconShape('M3.91 20.66c0-3.88 3.65-6.27 8.09-6.27s8.09 2.39 8.09 6.27', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const pencil = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M16.4 3.9 20.1 7.6 9.4 18.3l-4.6.9.9-4.6L16.4 3.9Z', stroke: true, roundJoin: true),
      AppIconShape('m14.2 6.1 3.7 3.7', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const megaphone = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M19 4.5v15l-9.5-4H6a2.5 2.5 0 0 1 0-5h3.5L19 4.5Z', stroke: true, roundJoin: true),
      AppIconShape('M8 15.5v2.8a1.7 1.7 0 0 0 3.4 0v-1.6', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const clock = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.6 12A8.4 8.4 0 1 0 20.4 12A8.4 8.4 0 1 0 3.6 12Z', stroke: true),
      AppIconShape('M12 7.6V12l2.9 1.9', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const pin = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M12 21c4-4.2 6-7.4 6-10a6 6 0 1 0-12 0c0 2.6 2 5.8 6 10Z', stroke: true, roundJoin: true),
      AppIconShape('M9.8 10.8A2.2 2.2 0 1 0 14.2 10.8A2.2 2.2 0 1 0 9.8 10.8Z', stroke: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const chevronLeft = AppIconData(
    strokeWidth: 2,
    outline: [
      AppIconShape('m14.5 5.5-7 6.5 7 6.5', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const chevronRight = AppIconData(
    strokeWidth: 2,
    outline: [
      AppIconShape('m9.5 5.5 7 6.5-7 6.5', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const chevronUpDown = AppIconData(
    strokeWidth: 2,
    outline: [
      AppIconShape('m8.5 10 3.5-3.5L15.5 10M8.5 14l3.5 3.5L15.5 14', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const camera = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.6 8.8a1.8 1.8 0 0 1 1.8-1.8h1.9l1.2-2h7l1.2 2h1.9a1.8 1.8 0 0 1 1.8 1.8v8.4a1.8 1.8 0 0 1-1.8 1.8H5.4a1.8 1.8 0 0 1-1.8-1.8V8.8Z', stroke: true, roundJoin: true),
      AppIconShape('M8.8 13A3.2 3.2 0 1 0 15.2 13A3.2 3.2 0 1 0 8.8 13Z', stroke: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const search = AppIconData(
    strokeWidth: 1.9,
    outline: [
      AppIconShape('M4.4 11A6.6 6.6 0 1 0 17.6 11A6.6 6.6 0 1 0 4.4 11Z', stroke: true),
      AppIconShape('m16 16 4 4', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const arrowUp = AppIconData(
    strokeWidth: 2.1,
    outline: [
      AppIconShape('M12 19V5m0 0-5.5 5.5M12 5l5.5 5.5', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const plus = AppIconData(
    strokeWidth: 2.1,
    outline: [
      AppIconShape('M12 5v14M5 12h14', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const check = AppIconData(
    strokeWidth: 2.2,
    outline: [
      AppIconShape('m5 12.5 4.6 4.5L19 7.5', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김 (XMark 를 가늘게)
  static const close = AppIconData(
    strokeWidth: 2,
    outline: [
      AppIconShape('M6.5 6.5 17.5 17.5M17.5 6.5 6.5 17.5', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const lock = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M7.2 10.2H16.8A2.4 2.4 0 0 1 19.2 12.6V17.4A2.4 2.4 0 0 1 16.8 19.8H7.2A2.4 2.4 0 0 1 4.8 17.4V12.6A2.4 2.4 0 0 1 7.2 10.2Z', stroke: true),
      AppIconShape('M8.2 10.2V7.8a3.8 3.8 0 0 1 7.6 0v2.4', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const bell = AppIconData(
    strokeWidth: 1.9,
    outline: [
      AppIconShape('M6 16.5V11a6 6 0 0 1 12 0v5.5l1.6 1.8H4.4z', stroke: true, roundJoin: true),
      AppIconShape('M10 20.5a2.2 2.2 0 0 0 4 0', stroke: true, roundCap: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const settings = AppIconData(
    strokeWidth: 1.9,
    outline: [
      AppIconShape('M10.206 5.027A1.9 1.9 0 1 1 13.794 5.027A7.2 7.2 0 0 1 15.662 5.801A1.9 1.9 0 1 1 18.199 8.338A7.2 7.2 0 0 1 18.973 10.206A1.9 1.9 0 1 1 18.973 13.794A7.2 7.2 0 0 1 18.199 15.662A1.9 1.9 0 1 1 15.662 18.199A7.2 7.2 0 0 1 13.794 18.973A1.9 1.9 0 1 1 10.206 18.973A7.2 7.2 0 0 1 8.338 18.199A1.9 1.9 0 1 1 5.801 15.662A7.2 7.2 0 0 1 5.027 13.794A1.9 1.9 0 1 1 5.027 10.206A7.2 7.2 0 0 1 5.801 8.338A1.9 1.9 0 1 1 8.338 5.801A7.2 7.2 0 0 1 10.206 5.027Z', stroke: true, roundJoin: true),
      AppIconShape('M8.9 12A3.1 3.1 0 1 0 15.1 12A3.1 3.1 0 1 0 8.9 12Z', stroke: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const voteStamp = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M2.8 12A9.2 9.2 0 1 0 21.2 12A9.2 9.2 0 1 0 2.8 12Z', stroke: true),
      AppIconShape('M12 2.8v18.4', stroke: true),
      AppIconShape('M12 12 18.505 18.505', stroke: true),
    ],
  );

  /// 애기애타 icons.tsx 에서 옮김
  static const google = AppIconData(
    strokeWidth: 0,
    outline: [
      AppIconShape('M21.8 10.2h-.8V10h-9v4h5.6a6 6 0 1 1-1.7-6.5l2.8-2.8A10 10 0 1 0 22 12c0-.6-.1-1.2-.2-1.8Z', fill: true, color: 0xFFFFC107),
      AppIconShape('m3.2 7.3 3.3 2.4A6 6 0 0 1 16 7.5l2.8-2.8A10 10 0 0 0 3.2 7.3Z', fill: true, color: 0xFFFF3D00),
      AppIconShape('M12 22a10 10 0 0 0 6.7-2.6l-3.1-2.6A6 6 0 0 1 6.4 14l-3.3 2.5A10 10 0 0 0 12 22Z', fill: true, color: 0xFF4CAF50),
      AppIconShape('M21.8 10.2H12v4h5.6a6 6 0 0 1-2 2.7l3.1 2.6c-.2.2 3.3-2.5 3.3-7.5 0-.6-.1-1.2-.2-1.8Z', fill: true, color: 0xFF1976D2),
    ],
  );

  static const chevronDown = AppIconData(
    strokeWidth: 2,
    outline: [
      AppIconShape('m5.5 9 6.5 6.5L18.5 9', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  static const copy = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M10.8 8.6H17.8A2.2 2.2 0 0 1 20 10.8V17.8A2.2 2.2 0 0 1 17.8 20H10.8A2.2 2.2 0 0 1 8.6 17.8V10.8A2.2 2.2 0 0 1 10.8 8.6Z', stroke: true),
      AppIconShape('M15.4 8.6V6.2A2.2 2.2 0 0 0 13.2 4H6.2A2.2 2.2 0 0 0 4 6.2v7a2.2 2.2 0 0 0 2.2 2.2h2.4', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  static const eye = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M2.8 12c1.9-3.9 5.2-6.2 9.2-6.2s7.3 2.3 9.2 6.2c-1.9 3.9-5.2 6.2-9.2 6.2S4.7 15.9 2.8 12Z', stroke: true, roundJoin: true),
      AppIconShape('M9.2 12A2.8 2.8 0 1 0 14.8 12A2.8 2.8 0 1 0 9.2 12Z', stroke: true),
    ],
  );

  static const eyeOff = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M2.8 12c1.9-3.9 5.2-6.2 9.2-6.2s7.3 2.3 9.2 6.2c-1.9 3.9-5.2 6.2-9.2 6.2S4.7 15.9 2.8 12Z', stroke: true, roundJoin: true),
      AppIconShape('M9.2 12A2.8 2.8 0 1 0 14.8 12A2.8 2.8 0 1 0 9.2 12Z', stroke: true),
      AppIconShape('M4.6 4.6 19.4 19.4', stroke: true, roundCap: true),
    ],
  );

  static const checkCircle = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.6 12A8.4 8.4 0 1 0 20.4 12A8.4 8.4 0 1 0 3.6 12Z', stroke: true),
      AppIconShape('m8.3 12.2 2.6 2.5 4.9-5.1', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  static const circle = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.6 12A8.4 8.4 0 1 0 20.4 12A8.4 8.4 0 1 0 3.6 12Z', stroke: true),
    ],
  );

  static const xCircle = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.6 12A8.4 8.4 0 1 0 20.4 12A8.4 8.4 0 1 0 3.6 12Z', stroke: true),
      AppIconShape('m9.3 9.3 5.4 5.4M14.7 9.3l-5.4 5.4', stroke: true, roundCap: true),
    ],
  );

  static const alertCircle = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.6 12A8.4 8.4 0 1 0 20.4 12A8.4 8.4 0 1 0 3.6 12Z', stroke: true),
      AppIconShape('M12 7.6v5.2', stroke: true, roundCap: true),
      AppIconShape('M12 16.3h.01', stroke: true, roundCap: true),
    ],
  );

  static const moreHoriz = AppIconData(
    strokeWidth: 0,
    outline: [
      AppIconShape('M4.6 12A1.6 1.6 0 1 0 7.8 12A1.6 1.6 0 1 0 4.6 12Z', fill: true),
      AppIconShape('M10.4 12A1.6 1.6 0 1 0 13.6 12A1.6 1.6 0 1 0 10.4 12Z', fill: true),
      AppIconShape('M16.2 12A1.6 1.6 0 1 0 19.4 12A1.6 1.6 0 1 0 16.2 12Z', fill: true),
    ],
  );

  static const moreVert = AppIconData(
    strokeWidth: 0,
    outline: [
      AppIconShape('M10.4 6.2A1.6 1.6 0 1 0 13.6 6.2A1.6 1.6 0 1 0 10.4 6.2Z', fill: true),
      AppIconShape('M10.4 12A1.6 1.6 0 1 0 13.6 12A1.6 1.6 0 1 0 10.4 12Z', fill: true),
      AppIconShape('M10.4 17.8A1.6 1.6 0 1 0 13.6 17.8A1.6 1.6 0 1 0 10.4 17.8Z', fill: true),
    ],
  );

  static const image = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M6 4.8H18A2.4 2.4 0 0 1 20.4 7.2V16.8A2.4 2.4 0 0 1 18 19.2H6A2.4 2.4 0 0 1 3.6 16.8V7.2A2.4 2.4 0 0 1 6 4.8Z', stroke: true),
      AppIconShape('M7.3 9.9A1.7 1.7 0 1 0 10.7 9.9A1.7 1.7 0 1 0 7.3 9.9Z', stroke: true),
      AppIconShape('m3.9 17.2 4.5-4.1a1.2 1.2 0 0 1 1.6 0l3 2.7 2.3-2a1.2 1.2 0 0 1 1.6 0l3.8 3.4', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  static const imagePlus = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M6 6H15A2.4 2.4 0 0 1 17.4 8.4V17.4A2.4 2.4 0 0 1 15 19.8H6A2.4 2.4 0 0 1 3.6 17.4V8.4A2.4 2.4 0 0 1 6 6Z', stroke: true),
      AppIconShape('m3.9 17.6 3.7-3.4a1.2 1.2 0 0 1 1.6 0l2.3 2.1 1.7-1.5a1.2 1.2 0 0 1 1.6 0l2.3 2', stroke: true, roundCap: true, roundJoin: true),
      AppIconShape('M19.4 2.6v6M16.4 5.6h6', stroke: true, roundCap: true),
    ],
  );

  static const folderPlus = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.5 6.2A1.7 1.7 0 0 1 5.2 4.5h3.3l1.7 2h8.6a1.7 1.7 0 0 1 1.7 1.7v9.6a1.7 1.7 0 0 1-1.7 1.7H5.2a1.7 1.7 0 0 1-1.7-1.7V6.2Z', stroke: true, roundJoin: true),
      AppIconShape('M12 10.2v5.6M9.2 13h5.6', stroke: true, roundCap: true),
    ],
  );

  static const chart = AppIconData(
    strokeWidth: 2,
    outline: [
      AppIconShape('M4.4 19.6h15.2', stroke: true, roundCap: true),
      AppIconShape('M7.4 16.2v-4.4M12 16.2V7.4M16.6 16.2v-6.6', stroke: true, roundCap: true),
    ],
  );

  static const trash = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M4.8 7.2h14.4', stroke: true, roundCap: true),
      AppIconShape('M9.4 7.2V5.6A1.4 1.4 0 0 1 10.8 4.2h2.4a1.4 1.4 0 0 1 1.4 1.4v1.6', stroke: true, roundCap: true, roundJoin: true),
      AppIconShape('M6.6 7.2l.9 11.3a1.8 1.8 0 0 0 1.8 1.7h5.4a1.8 1.8 0 0 0 1.8-1.7l.9-11.3', stroke: true, roundCap: true, roundJoin: true),
      AppIconShape('M10.2 11v5.2M13.8 11v5.2', stroke: true, roundCap: true),
    ],
  );

  static const heart = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M12 19.5c-4.9-3-8-6.2-8-9.9A4.1 4.1 0 0 1 8.1 5.5c1.6 0 3 .8 3.9 2.1.9-1.3 2.3-2.1 3.9-2.1A4.1 4.1 0 0 1 20 9.6c0 3.7-3.1 6.9-8 9.9Z', stroke: true, roundJoin: true),
    ],
    filled: [
      AppIconShape('M12 19.5c-4.9-3-8-6.2-8-9.9A4.1 4.1 0 0 1 8.1 5.5c1.6 0 3 .8 3.9 2.1.9-1.3 2.3-2.1 3.9-2.1A4.1 4.1 0 0 1 20 9.6c0 3.7-3.1 6.9-8 9.9Z', stroke: true, fill: true, roundJoin: true),
    ],
  );

  static const download = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M12 4.4v10.4m0 0-4.3-4.3M12 14.8l4.3-4.3', stroke: true, roundCap: true, roundJoin: true),
      AppIconShape('M4.8 19.6h14.4', stroke: true, roundCap: true),
    ],
  );

  static const sort = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M4.4 6.8h15.2M4.4 12h10.4M4.4 17.2h5.6', stroke: true, roundCap: true),
    ],
  );

  static const cake = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M5 12.4h14v6.4a1.4 1.4 0 0 1-1.4 1.4H6.4A1.4 1.4 0 0 1 5 18.8v-6.4Z', stroke: true, roundJoin: true),
      AppIconShape('M5 15.6c1.4 0 1.4 1.2 2.8 1.2s1.4-1.2 2.8-1.2 1.4 1.2 2.8 1.2 1.4-1.2 2.8-1.2 1.4 1.2 2.8 1.2', stroke: true, roundCap: true, roundJoin: true),
      AppIconShape('M9 12.4V9.6M12 12.4V9.6M15 12.4V9.6', stroke: true, roundCap: true),
      AppIconShape('M9 6.8v.3M12 6.8v.3M15 6.8v.3', stroke: true, roundCap: true),
    ],
  );

  static const gift = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M5.2 8.8H18.8A1.2 1.2 0 0 1 20 10V11.6A1.2 1.2 0 0 1 18.8 12.8H5.2A1.2 1.2 0 0 1 4 11.6V10A1.2 1.2 0 0 1 5.2 8.8Z', stroke: true),
      AppIconShape('M5.6 12.8v5.8a1.6 1.6 0 0 0 1.6 1.6h9.6a1.6 1.6 0 0 0 1.6-1.6v-5.8', stroke: true, roundCap: true, roundJoin: true),
      AppIconShape('M12 8.8v11.4', stroke: true, roundCap: true),
      AppIconShape('M12 8.8c-1-2.8-2.8-4.4-4.2-4.4a1.8 1.8 0 0 0 0 3.6c1.4.2 2.8.5 4.2.8Zm0 0c1-2.8 2.8-4.4 4.2-4.4a1.8 1.8 0 0 1 0 3.6c-1.4.2-2.8.5-4.2.8Z', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  static const send = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M20.2 3.8 3.8 10.4l6.6 3.2 3.2 6.6 6.6-16.4Z', stroke: true, roundJoin: true),
      AppIconShape('m10.4 13.6 4.4-4.4', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  static const star = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M12 4.3l2.35 4.76 5.25.77-3.8 3.7.9 5.23L12 16.29l-4.7 2.47.9-5.23-3.8-3.7 5.25-.77Z', stroke: true, roundJoin: true),
    ],
    filled: [
      AppIconShape('M12 4.3l2.35 4.76 5.25.77-3.8 3.7.9 5.23L12 16.29l-4.7 2.47.9-5.23-3.8-3.7 5.25-.77Z', stroke: true, fill: true, roundJoin: true),
    ],
  );

  static const logout = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M9.6 20H6.4A2 2 0 0 1 4.4 18V6a2 2 0 0 1 2-2h3.2', stroke: true, roundCap: true, roundJoin: true),
      AppIconShape('m15.2 16.2 4.2-4.2-4.2-4.2M19.4 12H9.6', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  static const book = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M12 6.2C10.4 4.9 8.3 4.4 4.4 4.6v13.6c3.9-.2 6 .3 7.6 1.6 1.6-1.3 3.7-1.8 7.6-1.6V4.6c-3.9-.2-6 .3-7.6 1.6Z', stroke: true, roundJoin: true),
      AppIconShape('M12 6.2v13.6', stroke: true, roundCap: true),
    ],
  );

  static const receipt = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M6 3.8h12v16.4l-2-1.3-2 1.3-2-1.3-2 1.3-2-1.3-2 1.3V3.8Z', stroke: true, roundJoin: true),
      AppIconShape('M9 8.4h6M9 11.8h6M9 15.2h3.6', stroke: true, roundCap: true),
    ],
  );

  static const bank = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M3.8 9 12 4.2 20.2 9H3.8Z', stroke: true, roundJoin: true),
      AppIconShape('M6 9v7.6M10 9v7.6M14 9v7.6M18 9v7.6M3.8 19.8h16.4', stroke: true, roundCap: true),
    ],
  );

  static const monitor = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M5.6 4.6H18.4A2 2 0 0 1 20.4 6.6V14.2A2 2 0 0 1 18.4 16.2H5.6A2 2 0 0 1 3.6 14.2V6.6A2 2 0 0 1 5.6 4.6Z', stroke: true),
      AppIconShape('M8.8 19.8h6.4M12 16.2v3.6', stroke: true, roundCap: true),
    ],
  );

  static const pushPin = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M9 3.8h6', stroke: true, roundCap: true),
      AppIconShape('M10.2 3.8v4.8L7 12.2v1.2h10v-1.2l-3.2-3.6V3.8', stroke: true, roundCap: true, roundJoin: true),
      AppIconShape('M12 13.4v6.8', stroke: true, roundCap: true),
    ],
  );

  static const mail = AppIconData(
    strokeWidth: 1.8,
    outline: [
      AppIconShape('M5.8 5.6H18.2A2.2 2.2 0 0 1 20.4 7.8V16.2A2.2 2.2 0 0 1 18.2 18.4H5.8A2.2 2.2 0 0 1 3.6 16.2V7.8A2.2 2.2 0 0 1 5.8 5.6Z', stroke: true),
      AppIconShape('m4.4 7.2 7.6 5.6 7.6-5.6', stroke: true, roundCap: true, roundJoin: true),
    ],
  );

  /// 이름별 전체 목록 — 테스트에서 모든 아이콘을 한 번씩 그려 볼 때 씁니다.
  static const Map<String, AppIconData> all = {
    'home': home,
    'heartHand': heartHand,
    'chat': chat,
    'calendar': calendar,
    'grid': grid,
    'users': users,
    'peopleCount': peopleCount,
    'person': person,
    'pencil': pencil,
    'megaphone': megaphone,
    'clock': clock,
    'pin': pin,
    'chevronLeft': chevronLeft,
    'chevronRight': chevronRight,
    'chevronUpDown': chevronUpDown,
    'camera': camera,
    'search': search,
    'arrowUp': arrowUp,
    'plus': plus,
    'check': check,
    'close': close,
    'lock': lock,
    'bell': bell,
    'settings': settings,
    'voteStamp': voteStamp,
    'google': google,
    'chevronDown': chevronDown,
    'copy': copy,
    'eye': eye,
    'eyeOff': eyeOff,
    'checkCircle': checkCircle,
    'circle': circle,
    'xCircle': xCircle,
    'alertCircle': alertCircle,
    'moreHoriz': moreHoriz,
    'moreVert': moreVert,
    'image': image,
    'imagePlus': imagePlus,
    'folderPlus': folderPlus,
    'chart': chart,
    'trash': trash,
    'heart': heart,
    'download': download,
    'sort': sort,
    'cake': cake,
    'gift': gift,
    'send': send,
    'star': star,
    'logout': logout,
    'book': book,
    'receipt': receipt,
    'bank': bank,
    'monitor': monitor,
    'pushPin': pushPin,
    'mail': mail,
  };
}
