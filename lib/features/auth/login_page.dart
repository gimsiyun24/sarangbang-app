import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cred = await signInWithGoogle();
      final user = cred.user;
      if (user == null) throw Exception('로그인 정보를 받지 못했어요.');

      // 초대코드 잠금이 켜져 있으면 여기서 한 번 확인
      final joinCode = await _requiredJoinCode();
      if (joinCode != null && mounted) {
        final ok = await _askJoinCode(joinCode);
        if (!ok) {
          await signOut();
          setState(() {
            _busy = false;
            _error = '초대코드가 맞지 않아요.';
          });
          return;
        }
      }
      await ensureMemberDoc(user);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = switch (e.code) {
            'popup-closed-by-user' => '로그인 창이 닫혔어요. 다시 시도해주세요.',
            'popup-blocked' => '브라우저가 팝업을 막았어요. 팝업을 허용한 뒤 다시 시도해주세요.',
            'unauthorized-domain' =>
              'Firebase 콘솔 → Authentication → Settings → 승인된 도메인에\n'
                  '이 주소를 추가해주세요.',
            _ => '로그인 실패: ${e.message ?? e.code}',
          });
    } catch (e) {
      setState(() => _error = '로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// groups/nw2026 의 joinCode 가 비어있지 않으면 잠금이 켜진 것
  Future<String?> _requiredJoinCode() async {
    try {
      final g = await Refs.group.get();
      final code = (g.data()?['joinCode'] ?? '') as String;
      return code.trim().isEmpty ? null : code.trim();
    } catch (_) {
      return null; // 못 읽으면 잠금 없는 것으로 취급
    }
  }

  Future<bool> _askJoinCode(String expected) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('초대코드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('사랑방 카톡에 공지된 코드를 입력해주세요.', style: AppText.caption),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: '예: nw2026'),
              onSubmitted: (_) => Navigator.pop(c, true),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 42)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('입장'),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    return ctrl.text.trim().toLowerCase() == expected.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3FAF6), Color(0xFFE7F3EC), Color(0xFFF6FAF7)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: AppShadow.raised,
                      ),
                      alignment: Alignment.center,
                      child: const Text('🍀', style: TextStyle(fontSize: 40)),
                    ),
                    const SizedBox(height: 26),
                    Text(AppConfig.groupName,
                        textAlign: TextAlign.center, style: AppText.display),
                    const SizedBox(height: 10),
                    Text('우리 사랑방의 1년이 남는 곳',
                        style: AppText.body.copyWith(color: AppColors.muted)),
                    const SizedBox(height: 40),

                    // 앱이 뭘 담는지 한눈에
                    const _Features(),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _login,
                        icon: _busy
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.g_mobiledata_rounded, size: 26),
                        label: Text(_busy ? '로그인 중...' : 'Google 계정으로 시작하기'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warnBg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 16, color: AppColors.warn),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: AppText.caption
                                      .copyWith(color: AppColors.warn)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 12, color: AppColors.faint),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            '"나만 보기" 기도제목은 본인 외 아무도 볼 수 없습니다',
                            style: AppText.micro,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  static const _items = [
    ('🙏', '기도제목·신앙루틴', '매주 쌓이고, 카톡 포맷으로 한 번에 복사'),
    ('📸', '사진 아카이브', '만료 없이 원본 그대로 보관'),
    ('📋', '모임·출석·정산', '누가 왔고 누가 냈는지 기록으로'),
  ];

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final (emoji, title, desc) in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: AppText.label.copyWith(fontSize: 13.5)),
                        const SizedBox(height: 2),
                        Text(desc, style: AppText.micro),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
