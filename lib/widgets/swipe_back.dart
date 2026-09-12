import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 오른쪽으로 밀어서 앞 화면으로 돌아가는 화면 — 제목 줄에 `<` 가 있는 화면들.
///
/// 애기애타 앱의 `use-swipe-back.ts` 와 같은 손짓입니다. 아이폰 기본 손짓은 화면
/// **왼쪽 가장자리 20px** 에서 시작해야 하지만, 여기서는 애기애타처럼 **화면 어디서든**
/// 오른쪽으로 밀면 돌아갑니다. 가장자리만 받으면 두 가지가 곤란합니다.
///  - 설정·내 프로필처럼 단추와 입력칸으로 꽉 찬 화면은 밀 자리를 찾기 어렵습니다.
///  - 사파리에서 왼쪽 가장자리를 미는 것은 브라우저 제 뒤로가기라 서로 부딪힙니다.
///
/// 밀린 만큼 화면이 손가락을 따라 나가고 그 뒤로 앞 화면이 드러나는데, 이것은
/// 우리가 따로 그리는 것이 아니라 **라우트의 전환 애니메이션을 손가락이 대신 미는 것**입니다
/// (아이폰 기본 손짓과 같은 방식). 그래서 [theme.dart] 의 화면 전환이 가로로 미끄러지는
/// 것이어야 뜻이 맞습니다 — 흐려지며 바뀌는 전환으로는 따라갈 화면이 없습니다.
///
/// 쓰는 곳은 [router.dart] 하나입니다.
/// ```dart
/// GoRoute(
///   path: '/settings',
///   pageBuilder: (c, s) => SwipeBackPage(key: s.pageKey, child: const SettingsPage()),
/// )
/// ```
/// 탭 화면 5개에는 쓰지 않습니다 — 돌아갈 앞 화면이 없습니다.
class SwipeBackPage<T> extends Page<T> {
  final Widget child;

  const SwipeBackPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) => _SwipeBackRoute<T>(this);
}

/// 화면 절반을 넘기지 않았어도 이만큼 빠르게 튕기면 그대로 나갑니다(초당 화면 폭).
const double _kFlingVelocity = 1.0;

/// 손을 뗀 뒤 끝까지 나가거나 제자리로 돌아가는 데 걸리는 시간.
const Duration _kSettleDuration = Duration(milliseconds: 350);

class _SwipeBackRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  _SwipeBackRoute(SwipeBackPage<T> page) : super(settings: page);

  // settings 를 거쳐 읽습니다. go_router 가 같은 자리에 새 Page 를 끼워 넣으면
  // Navigator 가 settings 를 바꿔치기하므로, 만들 때 받은 page 를 붙들고 있으면 안 됩니다.
  @override
  Widget buildContent(BuildContext context) => (settings as SwipeBackPage<T>).child;

  @override
  bool get maintainState => true;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      // 손짓을 받는 상자는 전환 애니메이션 **안쪽**에 둡니다. 화면과 함께 밀려나야
      // 밀고 있는 도중에도 손가락이 계속 같은 자리를 짚고 있는 것이 됩니다.
      super.buildTransitions(
        context,
        animation,
        secondaryAnimation,
        _SwipeBackDetector(
          enabled: _canSwipe,
          onStart: _startSwipe,
          child: child,
        ),
      );

  /// 지금 이 화면을 밀어서 닫아도 되는가 — 아이폰 기본 손짓과 같은 기준입니다.
  bool _canSwipe() {
    // 맨 아래 화면은 돌아갈 곳이 없고, 위에 다른 화면이 덮여 있으면 내 손짓이 아닙니다.
    if (isFirst || !isCurrent) return false;
    if (willHandlePopInternally) return false;
    // 화면 스스로 뒤로가기를 막고 있을 때(PopScope)는 손짓도 막습니다.
    if (popDisposition == RoutePopDisposition.doNotPop) return false;
    // 들어오거나 나가는 중이면 그 애니메이션이 controller 를 쓰고 있습니다.
    if (animation?.status != AnimationStatus.completed) return false;
    if (secondaryAnimation?.status != AnimationStatus.dismissed) return false;
    if (navigator?.userGestureInProgress ?? true) return false;
    return true;
  }

  _SwipeBackGesture _startSwipe() => _SwipeBackGesture(
        navigator: navigator!,
        controller: controller!,
        isCurrent: () => isCurrent,
        isActive: () => isActive,
      );
}

/// 미는 동안 화면의 전환 애니메이션을 손가락 대신 붙잡고 있는 것.
///
/// 0 이 앞 화면(다 밀려남), 1 이 이 화면(제자리)입니다.
/// navigator 와 controller 를 값으로 들고 있는 이유: 손을 떼고 나가는 도중에 이 화면은
/// 사라지므로, 그때 라우트를 거쳐 찾으려 하면 이미 없습니다.
class _SwipeBackGesture {
  final NavigatorState navigator;
  final AnimationController controller;
  final ValueGetter<bool> isCurrent;
  final ValueGetter<bool> isActive;

  _SwipeBackGesture({
    required this.navigator,
    required this.controller,
    required this.isCurrent,
    required this.isActive,
  }) {
    navigator.didStartUserGesture();
  }

  /// 화면 폭을 1로 본 거리만큼 밀렸습니다. 오른쪽으로 밀수록 0에 가까워집니다.
  /// 시작점보다 왼쪽으로는 넘어가지 않습니다(controller 가 0~1 을 벗어나지 않음).
  void update(double fraction) => controller.value -= fraction;

  /// 손을 뗐습니다. [velocity] 는 초당 화면 폭(오른쪽이 양수).
  void end(double velocity) {
    // 아이폰 화면 전환을 눈으로 맞춰 고른 곡선입니다(Flutter 의 Cupertino 와 같은 값).
    const curve = Curves.fastEaseInToSlowEaseOut;

    final bool stay;
    if (!isCurrent()) {
      // 미는 사이에 다른 곳에서 화면을 닫았다면, 민 거리와 상관없이 그쪽을 따릅니다.
      stay = isActive();
    } else if (velocity.abs() >= _kFlingVelocity) {
      stay = velocity <= 0;
    } else {
      // 애기애타와 같은 기준 — 화면 절반을 넘겼으면 나가고, 못 넘겼으면 제자리로.
      stay = controller.value > 0.5;
    }

    if (stay) {
      controller.animateTo(1, duration: _kSettleDuration, curve: curve);
    } else {
      if (isCurrent()) navigator.pop();
      // 이미 다 밀려나 있었으면 pop 만으로 끝나 애니메이션이 걸리지 않습니다.
      if (controller.isAnimating) {
        controller.animateBack(0, duration: _kSettleDuration, curve: curve);
      }
    }

    if (controller.isAnimating) {
      // 남은 애니메이션이 끝날 때까지 "손짓 중"으로 둡니다. 여기서 바로 풀면
      // 화면이 손가락을 따라가던 모양에서 제 전환 모양으로 중간에 튑니다.
      late final AnimationStatusListener done;
      done = (_) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(done);
      };
      controller.addStatusListener(done);
    } else {
      navigator.didStopUserGesture();
    }
  }
}

/// 화면 전체에서 가로로 미는 손짓을 받는 상자.
class _SwipeBackDetector extends StatefulWidget {
  final ValueGetter<bool> enabled;
  final ValueGetter<_SwipeBackGesture> onStart;
  final Widget child;

  const _SwipeBackDetector({
    required this.enabled,
    required this.onStart,
    required this.child,
  });

  @override
  State<_SwipeBackDetector> createState() => _SwipeBackDetectorState();
}

class _SwipeBackDetectorState extends State<_SwipeBackDetector> {
  _SwipeBackGesture? _gesture;

  /// 이번 손짓이 오른쪽으로 미는 것인지. 처음 움직일 때 한 번 정하고 끝까지 지킵니다.
  bool? _rightward;

  late final HorizontalDragGestureRecognizer _recognizer =
      HorizontalDragGestureRecognizer(debugOwner: this)
        // 손이 닿은 자리부터 잽니다. 그래야 처음 움직인 방향을 알 수 있고(아래 _onUpdate),
        // 화면이 손가락에 딱 붙어 따라옵니다.
        ..dragStartBehavior = DragStartBehavior.down
        ..onStart = _onStart
        ..onUpdate = _onUpdate
        ..onEnd = _onEnd
        ..onCancel = _onCancel;

  @override
  void dispose() {
    _recognizer.dispose();
    // 미는 도중에 화면이 사라졌다면 navigator 의 "손짓 중" 표시를 꺼 줍니다.
    // 안 끄면 그 다음부터 어떤 손짓도 시작되지 않습니다.
    final gesture = _gesture;
    if (gesture != null) {
      _gesture = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (gesture.navigator.mounted) gesture.navigator.didStopUserGesture();
      });
    }
    super.dispose();
  }

  void _onStart(DragStartDetails details) => _rightward = null;

  void _onUpdate(DragUpdateDetails details) {
    final width = context.size?.width ?? 0;
    final delta = details.primaryDelta ?? 0;
    if (width <= 0) return;

    if (_rightward == null) {
      if (delta == 0) return;
      // 왼쪽으로 시작한 손짓은 넘기기가 아닙니다. 이번 손짓은 여기서 접습니다.
      _rightward = delta > 0 && widget.enabled();
      if (!_rightward!) return;
      _gesture = widget.onStart();
    }

    _gesture?.update(delta / width);
  }

  void _onEnd(DragEndDetails details) {
    final width = context.size?.width ?? 1;
    _gesture?.end(details.velocity.pixelsPerSecond.dx / width);
    _gesture = null;
    _rightward = null;
  }

  void _onCancel() {
    _gesture?.end(0);
    _gesture = null;
    _rightward = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // 손짓 상자를 화면 위에 덮지 않고 감싸기만 합니다. 그래서 목록의 세로 스크롤이나
      // 글자 고르기처럼 안쪽이 먼저 가져가야 할 손짓은 안쪽이 가져갑니다.
      onPointerDown: (event) {
        if (widget.enabled()) _recognizer.addPointer(event);
      },
      child: widget.child,
    );
  }
}
