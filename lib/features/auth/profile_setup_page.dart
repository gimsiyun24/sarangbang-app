import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// 첫 로그인 직후 — 이름/별칭/생일만 받고 바로 시작
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});
  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  late final _name = TextEditingController(
      text: FirebaseAuth.instance.currentUser?.displayName ?? '');
  final _nickname = TextEditingController();
  int? _month, _day;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = ref.read(myUidProvider);
    if (uid == null) return;
    if (_name.text.trim().isEmpty) {
      toast(context, '이름을 입력해주세요.');
      return;
    }
    setState(() => _busy = true);
    try {
      await Refs.member(uid).set({
        'name': _name.text.trim(),
        'nickname': _nickname.text.trim(),
        'photoUrl': FirebaseAuth.instance.currentUser?.photoURL ?? '',
        'birthday': (_month != null && _day != null)
            ? '${_month.toString().padLeft(2, '0')}-${_day.toString().padLeft(2, '0')}'
            : '',
        'joinedAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) toast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🤍', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('반가워요!', style: AppText.display),
                  const SizedBox(height: 7),
                  Text('이것만 알려주시면 바로 시작합니다.',
                      style: AppText.body.copyWith(color: AppColors.inkMuted)),
                  const SizedBox(height: 30),
                  const _Label('이름'),
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(hintText: '예: 홍혜원'),
                  ),
                  const SizedBox(height: 18),
                  const _Label('별칭 (선택)'),
                  TextField(
                    controller: _nickname,
                    decoration:
                        const InputDecoration(hintText: '예: 평강, 나단, 샤인'),
                  ),
                  const SizedBox(height: 18),
                  const _Label('생일 (선택)'),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _month,
                          decoration: const InputDecoration(hintText: '월'),
                          items: [
                            for (var m = 1; m <= 12; m++)
                              DropdownMenuItem(value: m, child: Text('$m월'))
                          ],
                          onChanged: (v) => setState(() => _month = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _day,
                          decoration: const InputDecoration(hintText: '일'),
                          items: [
                            for (var d = 1; d <= 31; d++)
                              DropdownMenuItem(value: d, child: Text('$d일'))
                          ],
                          onChanged: (v) => setState(() => _day = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text('생일을 넣어두면 이번 달 생일자 배너와 롤링페이퍼가 열려요.',
                      style: AppText.micro),
                  const SizedBox(height: 30),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(_busy ? '저장 중...' : '사랑방 들어가기'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => signOut(),
                    child: const Text('다른 계정으로 로그인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text, style: AppText.label),
      );
}
