import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_config.dart';
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

class SarangbangApp extends StatefulWidget {
  const SarangbangApp({super.key});
  @override
  State<SarangbangApp> createState() => _SarangbangAppState();
}

class _SarangbangAppState extends State<SarangbangApp> {
  late final _router = buildRouter();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: '사랑방 나눔',
        // 웹에서는 이 색이 <meta name="theme-color"> 가 되어 폰 상단(상태바·주소창) 색을 정합니다.
        // 안 주면 테마의 주 색(파랑)이 들어가므로 화면 바탕과 같은 회색으로 둡니다.
        color: AppColors.canvas,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: _router,
        builder: (context, child) => MediaQuery.withNoTextScaling(child: child!),
      );
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
                  const Text(
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
                          style: const TextStyle(
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
