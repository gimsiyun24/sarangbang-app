import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/inbox.dart';
import '../../core/providers.dart';
import '../../shell.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// 알림함 — 제목 줄 종(알림 열기)으로 들어오는 화면. 애기애타 알림함과 같은 모양·동작입니다.
///
/// 한 줄을 누르면 그 화면으로 갑니다. 화면을 여는 순간 "다 봤다"고 적어 종의 빨간 점을 끄되,
/// 이번에 새로 온 줄은 열기 직전의 기준 시각으로 옅은 파랑 바탕을 남겨 무엇이 새로 왔는지 보이게 합니다.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  /// 새로 온 줄을 가를 기준 — 화면을 연 뒤 처음 알게 된 "지난번에 본 시각"을 붙잡아 둡니다.
  /// 다 봤다고 적으면 그 값이 지금 시각으로 바뀌는데, 그걸 따라가면 강조가 곧바로 사라집니다.
  DateTime? _baseline;
  bool _marked = false;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(myUidProvider);
    final me = ref.watch(myMemberProvider);
    final async = ref.watch(inboxProvider);

    if (me != null) {
      _baseline ??= me.noticesSeenAt ?? me.joinedAt ?? DateTime.now();
    }
    if (!_marked && uid != null && me != null) {
      _marked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => markInboxSeen(uid));
    }

    const listPadding = EdgeInsets.fromLTRB(16, 4, 16, 32);

    return SubPage(
      title: '알림',
      fallbackRoute: '/home',
      body: async.when(
        loading: () => ListView(
          padding: listPadding,
          children: [
            for (var i = 0; i < 3; i++)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Skeleton(height: 76, radius: AppRadius.lg),
              ),
          ],
        ),
        error: (e, _) => ListView(
          padding: listPadding,
          children: [SoftCard(padding: EdgeInsets.zero, child: ErrorNote(e))],
        ),
        data: (items) => items.isEmpty
            ? ListView(
                padding: listPadding,
                children: const [
                  SoftCard(
                    padding: EdgeInsets.zero,
                    child: EmptyState(icon: AppIcons.bell, title: '아직 온 알림이 없어요'),
                  ),
                ],
              )
            : ListView.separated(
                padding: listPadding,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isNew = _baseline != null &&
                      item.authorUid != uid &&
                      item.createdAt.isAfter(_baseline!);
                  return _InboxRow(item: item, isNew: isNew);
                },
              ),
      ),
    );
  }
}

/// 알림 종류마다의 그림 — 모임은 달력, 공지는 확성기, 투표는 기표 도장, 정산은 영수증
AppIconData _glyph(InboxKind kind) => switch (kind) {
      InboxKind.meeting => AppIcons.calendar,
      InboxKind.notice => AppIcons.megaphone,
      InboxKind.poll => AppIcons.voteStamp,
      InboxKind.settlement => AppIcons.receipt,
    };

/// 오늘은 시각, 어제는 "어제", 올해는 "9월 3일", 그 전은 "2025.9.3" (애기애타 formatChatListTime 과 같음)
String _listTime(DateTime t) {
  final now = DateTime.now();
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(t, now)) return DateFormat('a h:mm', 'ko_KR').format(t);
  if (sameDay(t, now.subtract(const Duration(days: 1)))) return '어제';
  if (t.year == now.year) return '${t.month}월 ${t.day}일';
  return '${t.year}.${t.month}.${t.day}';
}

class _InboxRow extends ConsumerWidget {
  final InboxItem item;
  final bool isNew;
  const _InboxRow({required this.item, required this.isNew});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SoftCard(
        padding: const EdgeInsets.all(14),
        color: isNew ? AppColors.brand50 : null,
        onTap: () {
          if (item.kind != InboxKind.meeting) switchRoom(ref, item.roomId);
          context.go(item.route);
        },
        child: Row(
          children: [
            // 모임 날짜 칸·다음 모임 카드와 같은 결로, 파랑을 꽉 채우고 그림은 흰색
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: AppIcon(_glyph(item.kind), size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong.copyWith(height: 1.3)),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(height: 1.3)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_listTime(item.createdAt), style: AppText.micro),
                const SizedBox(height: 4),
                const AppIcon(AppIcons.chevronRight, size: 16, color: AppColors.inkFaint),
              ],
            ),
          ],
        ),
      );
}
