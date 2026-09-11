import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_config.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../core/week.dart';
import '../../models/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/header_actions.dart';
import 'kakao_format.dart';
import 'prayer_edit_sheet.dart';

/// 기도제목 · 신앙루틴 — **내 분반 사랑방** 전용.
/// 전체 사랑방을 보고 있어도 여기는 항상 내 분반 것만 오갑니다.
class PrayerPage extends ConsumerWidget {
  const PrayerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(selectedWeekProvider);
    final myRoom = AppConfig.roomOf(ref.watch(myRoomIdProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('기도'),
        actions: [
          _WeekPicker(week: week),
          const HeaderActions(),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openPrayerEditor(context, ref, week: week),
        icon: const AppIcon(AppIcons.pencil),
        label: const Text('내 기도제목 쓰기'),
      ),
      body: SafeArea(
        child: Bounded(child: _WeekView(week: week, room: myRoom)),
      ),
    );
  }
}

// ─────────────────────────────────────────── 주차 선택
class _WeekPicker extends ConsumerWidget {
  final Week week;
  const _WeekPicker({required this.week});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: '주차 선택',
      position: PopupMenuPosition.under,
      onSelected: (id) =>
          ref.read(selectedWeekProvider.notifier).state = Week.fromId(id),
      itemBuilder: (c) => [
        for (final w in Week.recent(16))
          PopupMenuItem(
            value: w.id,
            child: Row(
              children: [
                Text(w.label,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            w.id == week.id ? FontWeight.w800 : FontWeight.w500)),
                if (w.isCurrent) ...[
                  const SizedBox(width: 6),
                  const Pill('이번 주'),
                ],
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(week.label,
                style: AppText.label.copyWith(color: AppColors.brand)),
            const AppIcon(AppIcons.chevronDown,
                size: 18, color: AppColors.brand),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 이번 주 나눔
class _WeekView extends ConsumerWidget {
  final Week week;
  final SarangRoom room;
  const _WeekView({required this.week, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(prayerEntriesProvider(week.id));
    final members = ref.watch(memberMapProvider);
    final roomMembers = ref.watch(myRoomMembersProvider);
    final notSubmitted = ref.watch(notSubmittedProvider(week.id));

    return async.when(
      loading: () => const ListSkeleton(),
      error: (e, _) => ErrorNote(e),
      data: (entries) {
        final visible = entries
            .where((e) => e.all.isNotEmpty || e.routines.isNotEmpty)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
          children: [
            _SubmitBar(
              week: week,
              room: room,
              submitted: roomMembers.length - notSubmitted.length,
              total: roomMembers.length,
              entries: entries,
              members: members,
              notSubmitted: notSubmitted,
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              EmptyState(
                icon: AppIcons.heartHand,
                title: '${week.mmdd} 주간, 아직 비어 있어요',
                subtitle: '첫 번째로 기도제목을 남겨보세요.',
              )
            else
              for (final e in visible) ...[
                _PrayerCard(entry: e, week: week, member: members[e.uid]),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _SubmitBar extends ConsumerWidget {
  final Week week;
  final SarangRoom room;
  final int submitted, total;
  final List<PrayerEntry> entries;
  final Map<String, Member> members;
  final List<Member> notSubmitted;

  const _SubmitBar({
    required this.week,
    required this.room,
    required this.submitted,
    required this.total,
    required this.entries,
    required this.members,
    required this.notSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = total == 0 ? 0.0 : submitted / total;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pill(room.name),
              const Spacer(),
              Text('${week.mmdd} 제출', style: AppText.caption),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$submitted', style: AppText.num.copyWith(fontSize: 22)),
              Text(' / $total명', style: AppText.caption),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Meter(ratio, height: 8),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => copyToClipboard(
                    context,
                    buildKakaoText(
                        week: week, entries: entries, members: members),
                    message: '카톡에 붙여넣기만 하면 돼요 📋',
                  ),
                  icon: const AppIcon(AppIcons.copy, size: 18),
                  label: const Text('카톡용 복사'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showNotSubmitted(context),
                  icon: const AppIcon(AppIcons.bell, size: 18),
                  label: Text('미제출 ${notSubmitted.length}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => _preview(context),
              icon: const AppIcon(AppIcons.eye, size: 15),
              label: const Text('복사될 내용 미리보기'),
              style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _preview(BuildContext context) {
    final text = buildKakaoText(week: week, entries: entries, members: members);
    openSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle('카톡 붙여넣기 미리보기'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.goldBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: SelectableText(text,
                style: const TextStyle(fontSize: 13, height: 1.65)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              copyToClipboard(context, text);
              Navigator.pop(context);
            },
            icon: const AppIcon(AppIcons.copy, size: 18),
            label: const Text('복사하기'),
          ),
          const SizedBox(height: 8),
          Text('🔒 나만 보기 항목은 여기에 들어가지 않습니다.',
              textAlign: TextAlign.center, style: AppText.micro),
        ],
      ),
    );
  }

  void _showNotSubmitted(BuildContext context) {
    openSheet(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHandle('${week.mmdd} 아직 안 낸 사람'),
          if (notSubmitted.isEmpty)
            const EmptyState(icon: AppIcons.checkCircle, title: '전원 제출 완료!')
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in notSubmitted)
                  Chip(
                    avatar: Avatar(member: m, size: 22),
                    label: Text(m.display),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                copyToClipboard(
                  context,
                  buildNudgeText(week: week, notSubmitted: notSubmitted),
                  message: '콕 찌르기 문구를 복사했어요',
                );
                Navigator.pop(context);
              },
              icon: const AppIcon(AppIcons.megaphone, size: 18),
              label: const Text('콕 찌르기 문구 복사'),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── 멤버 카드
class _PrayerCard extends ConsumerWidget {
  final PrayerEntry entry;
  final Week week;
  final Member? member;
  const _PrayerCard({required this.entry, required this.week, this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(myUidProvider);
    final isMine = uid == entry.uid;
    final reactions =
        ref.watch(prayerReactionsProvider(week.id)).value ?? const {};

    // 공개 항목 + (내 것이면) 나만 보기 항목
    final rows = <(int, PrayerTopic)>[];
    for (var i = 0; i < entry.topics.length; i++) {
      rows.add((i, entry.topics[i]));
    }
    if (isMine) {
      for (var i = 0; i < entry.private.length; i++) {
        rows.add((-(i + 1), entry.private[i])); // 음수 index = 비공개
      }
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(member: member, size: 36),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(member?.display ?? '이름없음',
                        style: AppText.cardTitle.copyWith(fontSize: 15)),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      const Pill('나'),
                    ],
                  ]),
                  if (entry.updatedAt != null)
                    Text(DateFormat('M/d HH:mm').format(entry.updatedAt!),
                        style: AppText.micro),
                ],
              ),
              const Spacer(),
              if (isMine)
                IconButton(
                  icon: const AppIcon(AppIcons.pencil, size: 18),
                  onPressed: () => openPrayerEditor(context, ref, week: week),
                ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final (idx, t) in rows)
              _TopicRow(
                topic: t,
                index: idx,
                week: week,
                targetUid: entry.uid,
                isMine: isMine,
                prayedBy: reactions['${entry.uid}#$idx'] ?? const [],
              ),
          ],
          if (entry.routines.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌱 ', style: TextStyle(fontSize: 13)),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final r in entry.routines) Pill(r)],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TopicRow extends ConsumerWidget {
  final PrayerTopic topic;
  final int index;
  final Week week;
  final String targetUid;
  final bool isMine;
  final List<String> prayedBy;

  const _TopicRow({
    required this.topic,
    required this.index,
    required this.week,
    required this.targetUid,
    required this.isMine,
    required this.prayedBy,
  });

  Future<void> _togglePray(WidgetRef ref) async {
    final uid = ref.read(myUidProvider);
    final room = ref.read(myRoomIdProvider);
    if (uid == null || room.isEmpty) return;
    final id = Refs.reactionId(week.id, targetUid, index, uid);
    final doc = Refs.prayerReactions(room).doc(id);
    if (prayedBy.contains(uid)) {
      await doc.delete();
    } else {
      await doc.set({
        'uid': uid,
        'weekId': week.id,
        'targetUid': targetUid,
        'topicIndex': index,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(myUidProvider);
    final iPrayed = uid != null && prayedBy.contains(uid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 11, 9, 11),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topic.isPrivate) ...[
              Padding(
                padding: EdgeInsets.only(top: 2),
                child:
                    AppIcon(AppIcons.lock, size: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(width: 5),
            ],
            Expanded(
              child: Text(topic.text,
                  style: AppText.body.copyWith(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            if (!isMine && !topic.isPrivate)
              InkWell(
                onTap: () => _togglePray(ref),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: iPrayed ? AppColors.brand : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                        color: iPrayed ? AppColors.brand : AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🙏', style: TextStyle(fontSize: 12)),
                      if (prayedBy.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text('${prayedBy.length}',
                            style: TextStyle(
                                fontFamily: kFontFamily,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color:
                                    iPrayed ? Colors.white : AppColors.inkMuted)),
                      ],
                    ],
                  ),
                ),
              )
            else if (prayedBy.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3, right: 6),
                child: Text('🙏 ${prayedBy.length}', style: AppText.micro),
              ),
          ],
        ),
      ),
    );
  }
}
