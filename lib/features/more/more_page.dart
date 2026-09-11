import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_config.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/room_switch.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myMemberProvider);
    final isLeader = ref.watch(isLeaderProvider);
    final room = ref.watch(currentRoomProvider);
    final roomMembers = ref.watch(currentRoomMembersProvider);
    final notices = ref.watch(currentNoticesProvider).value ?? const [];
    final uid = ref.watch(myUidProvider);
    final unread = notices.where((n) => !n.readBy.contains(uid)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('더보기'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(child: RoomSwitchChip(compact: true)),
          ),
        ],
      ),
      body: SafeArea(
        child: Bounded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              SoftCard(
                onTap: () => context.go('/more/profile'),
                child: Row(
                  children: [
                    Avatar(member: me, size: 48),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(me?.display ?? '', style: AppText.cardTitle),
                            if (isLeader) ...[
                              const SizedBox(width: 6),
                              const Pill('방장', icon: AppIcons.star),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            me == null || me.roomId.isEmpty
                                ? AppConfig.groupName
                                : AppConfig.roomOf(me.roomId).name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                    const AppIcon(AppIcons.chevronRight,
                        color: AppColors.inkFaint),
                  ],
                ),
              ),

              // 지금 보고 있는 사랑방 안내
              const SizedBox(height: 12),
              SoftCard(
                flat: true,
                color: AppColors.fill,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '아래 메뉴는 ${room.name} 기준이에요 · ${roomMembers.length}명',
                        style: AppText.caption,
                      ),
                    ),
                  ],
                ),
              ),

              const SectionTitle('기록'),
              _MenuCard(items: [
                _MenuItem(AppIcons.megaphone, '공지 게시판', '/more/notices',
                    badge: unread > 0 ? '$unread' : null),
                const _MenuItem(AppIcons.image, '사진 앨범', '/more/albums'),
                const _MenuItem(AppIcons.book, '말씀 노트', '/more/notes'),
              ]),

              const SectionTitle('운영'),
              const _MenuCard(items: [
                _MenuItem(AppIcons.voteStamp, '투표 / 일정 조율', '/more/polls'),
                _MenuItem(AppIcons.receipt, '정산 내역', '/more/settlements'),
                _MenuItem(AppIcons.cake, '멤버 · 생일', '/more/members'),
              ]),

              if (isLeader) ...[
                const SectionTitle('관리자'),
                const _MenuCard(items: [
                  _MenuItem(AppIcons.settings, '사랑방 관리', '/more/admin'),
                ]),
              ],

              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final ok = await confirm(context,
                        title: '로그아웃할까요?', ok: '로그아웃');
                    if (ok) await signOut();
                  },
                  icon: const AppIcon(AppIcons.logout, size: 16),
                  label: const Text('로그아웃'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('🍀 우리 사랑방의 1년이 남는 곳', style: AppText.micro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final AppIconData icon;
  final String label, route;
  final String? badge;
  const _MenuItem(this.icon, this.label, this.route, {this.badge});
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) => SoftCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              InkWell(
                onTap: () => context.go(items[i].route),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      AppIcon(items[i].icon, size: 22, color: AppColors.inkSoft),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(items[i].label,
                            style: AppText.bodyStrong
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (items[i].badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(items[i].badge!,
                              style: const TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const AppIcon(AppIcons.chevronRight,
                          size: 20, color: AppColors.inkFaint),
                    ],
                  ),
                ),
              ),
              if (i != items.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 46),
                  child: Divider(),
                ),
            ],
          ],
        ),
      );
}
