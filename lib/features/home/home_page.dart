import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_config.dart';
import '../../core/cloudinary.dart';
import '../../core/providers.dart';
import '../../core/refs.dart';
import '../../core/week.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/header_actions.dart';
import '../../widgets/room_switch.dart';
import '../prayer/prayer_edit_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myMemberProvider);

    return Scaffold(
      body: SafeArea(
        child: Bounded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            children: [
              _Greeting(name: me?.display ?? ''),
              const SizedBox(height: 14),
              const Align(
                  alignment: Alignment.centerLeft, child: RoomSwitchChip()),
              const SizedBox(height: 14),
              const _NextMeetingBanner(),
              const _BirthdayBanner(),
              const _RoutineCard(),
              const _PrayerNudge(),
              const _PinnedNotices(),
              const _RecentPhotos(),
              const SizedBox(height: 26),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('$name님', style: AppText.display.copyWith(fontSize: 23)),
        ),
        // 알림·내 프로필·설정 — 애기애타와 같이 모든 탭 제목 줄 오른쪽에 있습니다.
        // 맨 오른쪽 단추의 빈 여백만큼 4px 당겨 카드 끝과 맞춥니다.
        Transform.translate(
          offset: const Offset(4, 0),
          child: const HeaderActions(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────── 다음 모임 D-day
class _NextMeetingBanner extends ConsumerWidget {
  const _NextMeetingBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextMeetingProvider);

    if (next == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
          onTap: () => context.go('/meetings'),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const AppIcon(AppIcons.calendar, size: 22, color: AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('예정된 모임이 없어요. 일정을 등록해보세요.',
                    style: AppText.body.copyWith(fontSize: 13.5)),
              ),
              const AppIcon(AppIcons.chevronRight,
                  color: AppColors.inkFaint, size: 20),
            ],
          ),
        ),
      );
    }

    final (roomId, m) = next;
    final room = AppConfig.roomOf(roomId);
    final d = m.dday;
    final label = d == 0 ? 'TODAY' : (d > 0 ? 'D-$d' : 'D+${-d}');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        color: AppColors.brand,
        onTap: () => context.go('/meetings/$roomId/${m.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.white)),
                ),
                const SizedBox(width: 7),
                Text(room.name,
                    style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.8))),
                const Spacer(),
                Text(DateFormat('M월 d일 (E)', 'ko_KR').format(m.startAt),
                    style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
            const SizedBox(height: 14),
            Text(m.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.3,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Row(
              children: [
                AppIcon(AppIcons.clock,
                    size: 13, color: Colors.white.withValues(alpha: 0.75)),
                const SizedBox(width: 4),
                Text(DateFormat('a h:mm', 'ko_KR').format(m.startAt),
                    style: _light),
                if (m.place.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  AppIcon(AppIcons.pin,
                      size: 13, color: Colors.white.withValues(alpha: 0.75)),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(m.place,
                        overflow: TextOverflow.ellipsis, style: _light),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static final _light = TextStyle(
    fontFamily: kFontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: Colors.white.withValues(alpha: 0.88),
  );
}

// ─────────────────────────────────────────── 이번 달 생일자
class _BirthdayBanner extends ConsumerWidget {
  const _BirthdayBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(birthdayThisMonthProvider);
    if (list.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        color: AppColors.roseBg,
        flat: true,
        onTap: () => context.go('/more/members'),
        child: Row(
          children: [
            const AppIcon(AppIcons.cake, size: 24, color: AppColors.rose),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${now.month}월 생일',
                      style: AppText.micro.copyWith(color: AppColors.rose)),
                  const SizedBox(height: 3),
                  Text(
                    list.map((m) => '${m.display} ${m.birthDay}일').join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(fontSize: 13.5),
                  ),
                ],
              ),
            ),
            const AppIcon(AppIcons.chevronRight,
                color: AppColors.rose, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 오늘의 신앙루틴
class _RoutineCard extends ConsumerWidget {
  const _RoutineCard();

  Future<void> _toggle(WidgetRef ref, int i, List<int> current) async {
    final uid = ref.read(myUidProvider);
    final room = ref.read(myRoomIdProvider);
    if (uid == null || room.isEmpty) return;
    final next = [...current];
    next.contains(i) ? next.remove(i) : next.add(i);
    next.sort();
    await Refs.routineLog(room, uid, today()).set({
      'uid': uid,
      'date': today(),
      'done': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = Week.current();
    final mine = ref.watch(myPrayerProvider(week.id));
    final checked = ref.watch(myRoutineTodayProvider).value ?? const <int>[];
    final streak = ref.watch(myStreakProvider).value ?? 0;
    final todayCount = ref.watch(todayRoutineCountProvider).value ?? 0;
    final total = ref.watch(myRoomMembersProvider).length;
    final routines = mine?.routines ?? const <String>[];
    final doneAll = routines.isNotEmpty && checked.length >= routines.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          '오늘의 신앙루틴',
          trailing: streak > 0
              ? Pill('🔥 $streak일 연속',
                  bg: AppColors.goldBg, fg: AppColors.gold)
              : null,
        ),
        SoftCard(
          child: routines.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('아직 이번 주 루틴을 안 정하셨어요.',
                        style: AppText.body.copyWith(fontSize: 13.5)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () =>
                          openPrayerEditor(context, ref, week: week),
                      icon: const AppIcon(AppIcons.plus, size: 18),
                      label: const Text('루틴 정하기'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44)),
                    ),
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < routines.length; i++)
                      _RoutineRow(
                        text: routines[i],
                        checked: checked.contains(i),
                        onTap: () => _toggle(ref, i, checked),
                      ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(doneAll ? '🌳' : '🌱',
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            doneAll
                                ? '오늘 루틴 다 하셨어요!'
                                : (total == 0
                                    ? '오늘 $todayCount명이 함께했어요'
                                    : '오늘 $total명 중 $todayCount명이 함께했어요'),
                            style: AppText.caption,
                          ),
                        ),
                        if (total > 0)
                          SizedBox(
                            width: 52,
                            child: Meter(todayCount / total, height: 5),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final String text;
  final bool checked;
  final VoidCallback onTap;
  const _RoutineRow(
      {required this.text, required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 23,
                height: 23,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: checked ? AppColors.brand : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: checked ? AppColors.brand : AppColors.lineStrong,
                      width: 1.7),
                ),
                child: checked
                    ? const AppIcon(AppIcons.check,
                        size: 15, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: AppText.body.copyWith(
                    fontSize: 14,
                    fontWeight: checked ? FontWeight.w500 : FontWeight.w600,
                    color: checked ? AppColors.inkFaint : AppColors.inkSoft,
                    decoration:
                        checked ? TextDecoration.lineThrough : TextDecoration.none,
                    decorationColor: AppColors.inkFaint,
                  ),
                  child: Text(text),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────── 이번 주 기도제목 미제출 알림
class _PrayerNudge extends ConsumerWidget {
  const _PrayerNudge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = Week.current();
    final mine = ref.watch(myPrayerProvider(week.id));
    if (mine != null && (mine.all.isNotEmpty || mine.routines.isNotEmpty)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SoftCard(
        color: AppColors.goldBg,
        flat: true,
        onTap: () => openPrayerEditor(context, ref, week: week),
        child: Row(
          children: [
            const AppIcon(AppIcons.pencil, size: 22, color: AppColors.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${week.mmdd} 기도제목',
                      style: AppText.micro.copyWith(color: AppColors.gold)),
                  const SizedBox(height: 3),
                  Text('이번 주 나눔을 아직 안 올리셨어요',
                      style: AppText.bodyStrong.copyWith(fontSize: 13.5)),
                ],
              ),
            ),
            const AppIcon(AppIcons.chevronRight,
                color: AppColors.gold, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────── 고정 공지
class _PinnedNotices extends ConsumerWidget {
  const _PinnedNotices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(pinnedNoticesProvider).take(2).toList();
    if (pinned.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('고정 공지',
            trailing: TextButton(
              onPressed: () => context.go('/more/notices'),
              child: const Text('전체보기'),
            )),
        for (final (roomId, n) in pinned) ...[
          SoftCard(
            onTap: () {
              switchRoom(ref, roomId);
              context.go('/more/notices');
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcon(AppIcons.pushPin, size: 18, color: AppColors.brand),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(n.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyStrong),
                        ),
                        const SizedBox(width: 6),
                        Text(AppConfig.roomOf(roomId).name,
                            style: AppText.micro),
                      ]),
                      const SizedBox(height: 5),
                      Text(n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────── 최근 사진
class _RecentPhotos extends ConsumerWidget {
  const _RecentPhotos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomId = ref.watch(currentRoomIdProvider);
    final photos = ref.watch(recentPhotosProvider).value ?? const [];
    if (photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle('최근 사진',
            trailing: TextButton(
              onPressed: () => context.go('/more/albums'),
              child: const Text('앨범으로'),
            )),
        SizedBox(
          height: 96,
          child: Row(
            children: [
              for (var i = 0; i < photos.length; i++) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        context.go('/more/albums/$roomId/${photos[i].$1}'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image.network(
                        Cloudinary.thumb(photos[i].$2.publicId, size: 240),
                        fit: BoxFit.cover,
                        height: 96,
                        errorBuilder: (a, b, c) =>
                            Container(color: AppColors.brand50),
                      ),
                    ),
                  ),
                ),
                if (i != photos.length - 1) const SizedBox(width: 7),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    final week = Week.current();
    return Center(
      child: Text('${week.label} · ${week.range}', style: AppText.micro),
    );
  }
}
