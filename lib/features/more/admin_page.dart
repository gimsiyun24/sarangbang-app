import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_config.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../prayer/kakao_format.dart';

/// 사랑방장 전용 — 주차 마감, 미제출자 관리, 설정 확인
class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLeader = ref.watch(isLeaderProvider);
    final group = ref.watch(groupProvider).value ?? const {};
    final members = ref.watch(myRoomMembersProvider);
    final myRoom = AppConfig.roomOf(ref.watch(myRoomIdProvider));
    final week = ref.watch(selectedWeekProvider);
    final roomId = ref.watch(myRoomIdProvider);
    final notSubmitted = ref.watch(notSubmittedProvider(week.id));

    if (!isLeader) {
      return const SubPage(
        title: '사랑방 관리',
        body: EmptyState(
          icon: AppIcons.lock,
          title: '사랑방장만 볼 수 있어요',
          subtitle: 'Firebase 콘솔 → groups/nw2026 문서에\nleaderUid 필드로 본인 uid 를 넣으면 열립니다.',
        ),
      );
    }

    return SubPage(
      title: '사랑방 관리',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          SectionTitle('${myRoom.name} · 이번 주 기도제목'),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KV('주차', '${week.label}  (${week.id})'),
                KV('제출', '${members.length - notSubmitted.length} / ${members.length}명'),
                if (notSubmitted.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final m in notSubmitted) Pill(m.display),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => copyToClipboard(
                    context,
                    buildNudgeText(week: week, notSubmitted: notSubmitted),
                    message: '콕 찌르기 문구를 복사했어요',
                  ),
                  icon: const AppIcon(AppIcons.megaphone, size: 18),
                  label: const Text('콕 찌르기 문구 복사'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await confirm(context,
                        title: '${week.label}을 마감할까요?',
                        message: '마감해도 수정은 계속 가능합니다.\n기록용 표시입니다.',
                        ok: '마감');
                    if (!ok) return;
                    await Refs.week(roomId, week.id)
                        .set({'closed': true}, SetOptions(merge: true));
                    if (context.mounted) toast(context, '마감했어요');
                  },
                  icon: const AppIcon(AppIcons.lock, size: 18),
                  label: const Text('이 주차 마감 표시'),
                ),
              ],
            ),
          ),
          const SectionTitle('사랑방 설정'),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KV('사랑방', '${group['name'] ?? AppConfig.groupName}'),
                KV('문서 경로', 'groups/${AppConfig.groupId}/rooms/$roomId'),
                KV(
                  '초대코드',
                  '${group['joinCode'] ?? ''}'.trim().isEmpty
                      ? '꺼짐 (누구나 Google 로그인으로 입장)'
                      : '켜짐 — "${group['joinCode']}"',
                ),
                KV('멤버 수', '우리 분반 ${members.length}명 · 청년부 전체 ${(ref.watch(membersProvider).value ?? const []).length}명'),
                const SizedBox(height: 12),
                const Text(
                  '초대코드는 Firebase 콘솔 → groups/nw2026 문서의 joinCode 필드를\n'
                  '채우면 켜지고, 비우면 꺼집니다. (앱 재배포 불필요)',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.inkMuted, height: 1.6),
                ),
              ],
            ),
          ),
          const SectionTitle('연결 상태'),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Check('Firebase', AppConfig.isFirebaseConfigured,
                    AppConfig.firebaseProjectId),
                const SizedBox(height: 10),
                _Check('Cloudinary', AppConfig.isCloudinaryConfigured,
                    AppConfig.cloudinaryCloudName),
                const SizedBox(height: 10),
                _Check(
                    '원본 업로드 프리셋',
                    AppConfig.cloudinaryOriginalPreset.isNotEmpty,
                    AppConfig.cloudinaryOriginalPreset.isEmpty
                        ? '미설정 (선택 사항)'
                        : AppConfig.cloudinaryOriginalPreset),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '승인 절차가 없으므로 보안 규칙이 보장하는 범위는\n'
            '"Google 로그인을 한 사람만 볼 수 있다" 까지입니다.\n'
            '외부 유입이 신경 쓰이면 초대코드를 켜주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.5, color: AppColors.inkMuted, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final String label, value;
  final bool ok;
  const _Check(this.label, this.ok, this.value);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          AppIcon(ok ? AppIcons.checkCircle : AppIcons.alertCircle,
              size: 17, color: ok ? AppColors.brand : AppColors.danger),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Flexible(
            child: Text(value.isEmpty ? '미설정' : value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
          ),
        ],
      );
}
