import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../models/models.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});
  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  bool _byBirthday = true;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(membersProvider);

    return SubPage(
      title: '멤버 · 생일',
      actions: [
        IconButton(
          tooltip: _byBirthday ? '이름순 보기' : '생일순 보기',
          icon: AppIcon(_byBirthday ? AppIcons.sort : AppIcons.cake),
          onPressed: () => setState(() => _byBirthday = !_byBirthday),
        ),
      ],
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorNote(e),
        data: (members) {
          if (members.isEmpty) {
            return const EmptyState(icon: AppIcons.users, title: '아직 멤버가 없어요');
          }
          if (!_byBirthday) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: [
                for (final m in members) ...[
                  _MemberTile(member: m),
                  const SizedBox(height: 10),
                ],
              ],
            );
          }

          // 생일 캘린더 — 월별 그룹
          final withBd = members.where((m) => m.birthMonth != null).toList()
            ..sort((a, b) {
              final c = a.birthMonth!.compareTo(b.birthMonth!);
              return c != 0 ? c : (a.birthDay ?? 0).compareTo(b.birthDay ?? 0);
            });
          final without = members.where((m) => m.birthMonth == null).toList();
          final thisMonth = DateTime.now().month;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              for (var mm = 1; mm <= 12; mm++)
                if (withBd.any((m) => m.birthMonth == mm)) ...[
                  SectionTitle('$mm월',
                      trailing: mm == thisMonth
                          ? const Pill('이번 달', icon: AppIcons.gift)
                          : null),
                  for (final m in withBd.where((m) => m.birthMonth == mm)) ...[
                    _MemberTile(member: m, showBirthday: true),
                    const SizedBox(height: 10),
                  ],
                ],
              if (without.isNotEmpty) ...[
                const SectionTitle('생일 미등록'),
                for (final m in without) ...[
                  _MemberTile(member: m),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final Member member;
  final bool showBirthday;
  const _MemberTile({required this.member, this.showBirthday = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = member.daysToBirthday;
    final isToday = days == 0;

    return SoftCard(
      color: isToday ? AppColors.roseBg : null,
      onTap: member.birthMonth == null
          ? null
          : () => openSheet(context, _RollingPaper(member: member)),
      child: Row(
        children: [
          Avatar(member: member, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.display,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    if (member.nickname.isNotEmpty &&
                        member.name.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(member.name,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkMuted)),
                    ],
                    if (isToday) ...[
                      const SizedBox(width: 6),
                      const AppIcon(AppIcons.cake, size: 18, color: AppColors.rose),
                    ],
                  ],
                ),
                if (member.bio.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(member.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.inkMuted)),
                ],
              ],
            ),
          ),
          if (showBirthday && member.birthMonth != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${member.birthMonth}/${member.birthDay}',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand)),
                if (days != null && days <= 30)
                  Text(isToday ? '오늘!' : 'D-$days',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkMuted)),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── 롤링페이퍼
class _RollingPaper extends ConsumerStatefulWidget {
  final Member member;
  const _RollingPaper({required this.member});
  @override
  ConsumerState<_RollingPaper> createState() => _RollingPaperState();
}

class _RollingPaperState extends ConsumerState<_RollingPaper> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  String get _year => DateTime.now().year.toString();

  /// 생일 당일부터 공개 (그 해가 끝날 때까지 계속 열려 있습니다)
  bool get _revealed {
    final now = DateTime.now();
    final b = widget.member.birthdayIn(now.year);
    if (b == null) return false;
    return !DateTime(now.year, now.month, now.day).isBefore(b);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final uid = ref.read(myUidProvider)!;
      await Refs.birthdayCards(widget.member.uid, _year).add({
        'authorUid': uid,
        'message': _ctrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      _ctrl.clear();
      if (mounted) toast(context, '축하 메시지를 남겼어요 🎉');
    } catch (e) {
      if (mounted) toast(context, '실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final members = ref.watch(memberMapProvider);
    final days = m.daysToBirthday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHandle('${m.display}님 롤링페이퍼'),
        Row(
          children: [
            Avatar(member: m, size: 44),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.birthMonth}월 ${m.birthDay}일',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                Text(
                  days == 0
                      ? '오늘이 생일이에요! 🎂'
                      : (days == null ? '' : '생일까지 D-$days'),
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: Refs.birthdayCards(m.uid, _year)
              .orderBy('createdAt')
              .snapshots(),
          builder: (c, snap) {
            if (!snap.hasData) return const Loading();
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const EmptyState(
                icon: AppIcons.mail,
                title: '아직 메시지가 없어요',
                subtitle: '첫 번째 축하를 남겨보세요.',
              );
            }
            if (!_revealed) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.roseBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const AppIcon(AppIcons.gift, size: 34, color: AppColors.rose),
                    const SizedBox(height: 8),
                    Text('${docs.length}개의 축하가 모였어요',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('생일 당일에 함께 공개됩니다',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.inkMuted)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final d in docs)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.roseBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            members[d.data()['authorUid']]?.display ?? '익명',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.rose)),
                        const SizedBox(height: 6),
                        Text('${d.data()['message']}',
                            style:
                                const TextStyle(fontSize: 13.5, height: 1.65)),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: '축하 메시지를 남겨주세요 🎉',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _busy ? null : _send,
          icon: const AppIcon(AppIcons.send, size: 18),
          label: Text(_busy ? '보내는 중...' : '남기기'),
        ),
      ],
    );
  }
}
