import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_config.dart';
import 'core/display_settings.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  if (!AppConfig.isFirebaseConfigured) {
    runApp(const _SetupNeededApp());
    return;
  }

  try {
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
  } catch (e) {
    runApp(_SetupNeededApp(error: e.toString()));
    return;
  }

  runApp(const ProviderScope(child: SarangbangApp()));
}

class SarangbangApp extends ConsumerStatefulWidget {
  const SarangbangApp({super.key});
  @override
  ConsumerState<SarangbangApp> createState() => _SarangbangAppState();
}

class _SarangbangAppState extends ConsumerState<SarangbangApp>
    with WidgetsBindingObserver {
  late final _router = buildRouter();

  /// 지난번에 그린 밝기 — 바뀌었을 때만 앱 전체를 다시 그립니다.
  Brightness? _painted;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱을 켜 둔 채로 폰의 다크 모드가 바뀌면 그때도 따라갑니다(설정에서 직접 고르지 않았을 때).
  @override
  void didChangePlatformBrightness() {
    ref.read(platformBrightnessProvider.notifier).state =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = ref.watch(resolvedBrightnessProvider);
    AppColors.use(brightness);
    if (_painted != null && _painted != brightness) {
      // 색 토큰은 부를 때마다 지금 벌을 읽지만, 이미 그려진 화면은 스스로 다시 그리지 않습니다.
      // 밝기가 바뀐 이번 프레임 뒤에 앱 전체를 한 번 다시 그려, 모든 화면이 새 색을 읽게 합니다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildAll(context);
      });
    }
    _painted = brightness;

    return MaterialApp.router(
      title: '사랑방 나눔',
      // 웹에서는 이 색이 <meta name="theme-color"> 가 되어 폰 상단(상태바·주소창) 색을 정합니다.
      // 안 주면 테마의 주 색(파랑)이 들어가므로 화면 바탕과 같은 색으로 둡니다.
      color: AppColors.canvas,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
      builder: (context, child) => _Zoom(child: child!),
    );
  }
}

/// 이 위젯 아래의 모든 화면을 다시 그리게 표시합니다.
void _rebuildAll(BuildContext context) {
  void mark(Element element) {
    element.markNeedsBuild();
    element.visitChildren(mark);
  }

  (context as Element).visitChildren(mark);
}

/// app_config.dart 를 아직 안 채운 상태에서 뜨는 안내 화면
class _SetupNeededApp extends StatelessWidget {
  final String? error;
  const _SetupNeededApp({this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🍀', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  const Text('설정이 한 걸음 남았어요',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text(
                    'lib/app_config.dart 파일을 열어서\n'
                    'Firebase 값 5개와 Cloudinary 값 2개를 채워주세요.',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'firebaseApiKey\n'
                      'firebaseAuthDomain\n'
                      'firebaseProjectId\n'
                      'firebaseMessagingSenderId\n'
                      'firebaseAppId\n\n'
                      'cloudinaryCloudName\n'
                      'cloudinaryUploadPreset',
                      style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.7,
                          color: AppColors.brand),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '값 위치: Firebase 콘솔 → 프로젝트 설정(⚙️) → 내 앱 → firebaseConfig\n'
                    '자세한 건 02_Firebase설정가이드.md / 03_Cloudinary설정가이드.md 참고',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.inkMuted, height: 1.6),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('Firebase 초기화 오류\n$error',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.danger, height: 1.5)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 설정 화면의 글씨 크기 — 글씨만이 아니라 화면 전체를 확대·축소합니다.
/// 애기애타의 CSS zoom 과 같은 방식이라 여백·아이콘도 함께 커지고, 보이는 폭은 그만큼 좁아집니다.
///
/// 중간(1배)일 때도 같은 모양으로 감쌉니다. 크기를 바꿀 때 감싸는 위젯이 생겼다 없어지면
/// 그 아래 화면들이 통째로 새로 만들어져 보던 자리를 잃습니다.
class _Zoom extends ConsumerWidget {
  final Widget child;
  const _Zoom({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(textSizeProvider).zoom;
    final mq = MediaQuery.of(context);
    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: mq.size.width / zoom,
        height: mq.size.height / zoom,
        child: MediaQuery(
          data: mq.copyWith(
            size: mq.size / zoom,
            padding: mq.padding / zoom,
            viewPadding: mq.viewPadding / zoom,
            viewInsets: mq.viewInsets / zoom,
            systemGestureInsets: mq.systemGestureInsets / zoom,
            textScaler: TextScaler.noScaling,
          ),
          child: child,
        ),
      ),
    );
  }
}
