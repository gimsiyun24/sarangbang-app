import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_config.dart';
import '../../core/cloudinary.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  TextEditingController? _name, _nickname, _bio;
  int? _month, _day;
  String _roomId = '';
  bool _busy = false, _uploading = false;

  void _sync() {
    final me = ref.read(myMemberProvider);
    if (me == null || _name != null) return;
    _name = TextEditingController(text: me.name);
    _nickname = TextEditingController(text: me.nickname);
    _bio = TextEditingController(text: me.bio);
    _month = me.birthMonth;
    _day = me.birthDay;
    _roomId = me.roomId;
  }

  @override
  void dispose() {
    _name?.dispose();
    _nickname?.dispose();
    _bio?.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    if (!AppConfig.isCloudinaryConfigured) {
      toast(context, 'Cloudinary 설정이 필요해요.');
      return;
    }
    final f = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (f == null) return;
    setState(() => _uploading = true);
    try {
      final up = await Cloudinary.upload(await f.readAsBytes(), f.name);
      await Refs.member(ref.read(myUidProvider)!).update({
        'photoUrl': Cloudinary.thumb(up.publicId, size: 400),
      });
      if (mounted) toast(context, '프로필 사진을 바꿨어요');
    } catch (e) {
      if (mounted) toast(context, '실패: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await Refs.member(ref.read(myUidProvider)!).set({
        'name': _name!.text.trim(),
        'nickname': _nickname!.text.trim(),
        'bio': _bio!.text.trim(),
        'birthday': (_month != null && _day != null)
            ? '${_month.toString().padLeft(2, '0')}-${_day.toString().padLeft(2, '0')}'
            : '',
        if (_roomId.isNotEmpty) 'roomId': _roomId,
      }, SetOptions(merge: true));
      if (mounted) toast(context, '저장했어요');
    } catch (e) {
      if (mounted) toast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(myMemberProvider);
    _sync();
    if (me == null || _name == null) {
      return const SubPage(title: '내 프로필', body: Loading());
    }

    return SubPage(
      title: '내 프로필',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: Stack(
              children: [
                Avatar(member: me, size: 92),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: _uploading ? null : _changePhoto,
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _uploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt_rounded,
                              size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const _L('이름'),
          TextField(controller: _name),
          const SizedBox(height: 16),
          const _L('별칭'),
          TextField(
            controller: _nickname,
            decoration: const InputDecoration(hintText: '예: 평강, 나단, 샤인'),
          ),
          const SizedBox(height: 16),
          const _L('생일'),
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
          const SizedBox(height: 16),
          const _L('내 분반 사랑방'),
          Row(
            children: [
              for (final r in AppConfig.classRooms) ...[
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _roomId = r.id),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: _roomId == r.id
                            ? AppColors.brand50
                            : AppColors.fill,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _roomId == r.id
                              ? AppColors.brand
                              : Colors.transparent,
                          width: 1.6,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(r.emoji, style: const TextStyle(fontSize: 17)),
                          const SizedBox(height: 4),
                          Text(r.name,
                              style: AppText.label.copyWith(
                                fontSize: 12.5,
                                color: _roomId == r.id
                                    ? AppColors.brand
                                    : AppColors.inkMuted,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                if (r != AppConfig.classRooms.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text('분반을 옮기면 기도제목·신앙루틴도 그 사랑방 기준으로 바뀝니다.',
              style: AppText.micro),
          const SizedBox(height: 16),
          const _L('한 줄 소개'),
          TextField(
            controller: _bio,
            decoration: const InputDecoration(hintText: '예: 유아부 교사 / 대구 거주'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? '저장 중...' : '저장하기'),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            '표시 이름 기준: ${AppConfig.preferNickname ? '별칭 우선' : '실명 우선'}\n'
            '(lib/app_config.dart 의 preferNickname 으로 바꿀 수 있어요)',
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.inkMuted, height: 1.6),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () async {
                final ok = await confirm(
                  context,
                  title: '사랑방에서 나갈까요?',
                  message: '내 프로필과 기도제목이 삭제됩니다.\n사진·공지 등 이미 올린 기록은 남습니다.',
                  ok: '나가기',
                  danger: true,
                );
                if (!ok) return;
                await Refs.member(ref.read(myUidProvider)!).delete();
                await signOut();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('사랑방 나가기 / 데이터 삭제',
                  style: TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _L extends StatelessWidget {
  final String text;
  const _L(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft)),
      );
}
