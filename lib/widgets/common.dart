import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme.dart';
import 'glass.dart';
import 'app_icon.dart';
import 'app_icons.dart';

export 'app_icon.dart';
export 'app_icons.dart';

/// 화면 최대폭 — 웹에서 너무 넓어지지 않게 (애기애타 본문 폭과 같음)
class Bounded extends StatelessWidget {
  final Widget child;
  final double max;
  const Bounded({super.key, required this.child, this.max = 560});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: max),
          child: child,
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsets padding;
  const SectionTitle(this.text,
      {super.key,
      this.trailing,
      this.padding = const EdgeInsets.fromLTRB(0, 24, 0, 12)});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(
          children: [
            Text(text, style: AppText.section),
            const Spacer(),
            ?trailing,
          ],
        ),
      );
}

/// 앱 전체의 기본 카드. 테두리 대신 옅은 이중 그림자로 회색 바탕에서 띄웁니다.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  final bool flat;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(17),
    this.onTap,
    this.color,
    this.gradient,
    this.radius = AppRadius.lg,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: br,
        boxShadow: flat ? null : AppShadow.card,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: br,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          splashColor: onTap == null ? Colors.transparent : null,
          highlightColor: onTap == null ? Colors.transparent : null,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final Member? member;
  final double size;
  final bool ring;
  const Avatar({super.key, required this.member, this.size = 40, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final m = member;
    final url = m?.photoUrl ?? '';
    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.brand50,
        image: url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: url.isNotEmpty
          ? null
          : Text(
              m?.initial ?? '?',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontFamilyFallback: kFontFallback,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
                letterSpacing: -0.5,
              ),
            ),
    );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        boxShadow: AppShadow.card,
      ),
      child: inner,
    );
  }
}

/// 목록이 비었을 때 보여주는 안내. 애기애타처럼 동그라미 바탕 없이 가운데에 둡니다.
class EmptyState extends StatelessWidget {
  final AppIconData? icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                AppIcon(icon!, size: 40, color: AppColors.brand300),
                const SizedBox(height: 12),
              ],
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppText.bodyStrong.copyWith(color: AppColors.inkSoft)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!,
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(color: AppColors.inkFaint)),
              ],
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      );
}

/// 스피너 대신 쓰는 스켈레톤 — 로딩이 덜 답답해 보입니다.
class Skeleton extends StatefulWidget {
  final double height, width, radius;
  const Skeleton(
      {super.key,
      this.height = 14,
      this.width = double.infinity,
      this.radius = 8});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (c, _) => Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(
                AppColors.skeletonBase, AppColors.skeletonShine, _c.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      );
}

/// 목록 로딩용 스켈레톤 카드 몇 장
class ListSkeleton extends StatelessWidget {
  final int count;
  const ListSkeleton({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: count,
        separatorBuilder: (a, b) => const SizedBox(height: 12),
        itemBuilder: (c, i) => const SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Skeleton(width: 34, height: 34, radius: 99),
                SizedBox(width: 10),
                Skeleton(width: 84, height: 13),
              ]),
              SizedBox(height: 16),
              Skeleton(height: 12),
              SizedBox(height: 9),
              Skeleton(height: 12, width: 190),
            ],
          ),
        ),
      );
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(44),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
}

class ErrorNote extends StatelessWidget {
  final Object error;
  const ErrorNote(this.error, {super.key});

  @override
  Widget build(BuildContext context) {
    final msg = error.toString();
    final permission = msg.contains('permission-denied');
    return EmptyState(
      icon: permission ? AppIcons.lock : AppIcons.alertCircle,
      title: permission ? '읽을 권한이 없어요' : '불러오지 못했어요',
      subtitle: permission
          ? 'Firestore 보안 규칙이 게시되었는지,\ngroups/nw2026 문서가 있는지 확인해주세요.'
          : msg,
    );
  }
}

/// 라벨 + 값 한 줄
class KV extends StatelessWidget {
  final String k, v;
  const KV(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 78, child: Text(k, style: AppText.caption)),
            Expanded(child: Text(v, style: AppText.body)),
          ],
        ),
      );
}

/// 짧은 상태 표시. 기본은 옅은 파랑 바탕 + 파랑 글씨 (애기애타 Badge 와 같은 모양)
class Pill extends StatelessWidget {
  final String text;
  final Color? bg, fg;
  final AppIconData? icon;
  const Pill(this.text, {super.key, this.bg, this.fg, this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(icon == null ? 10 : 8, 4, 10, 4),
        decoration: BoxDecoration(
          color: bg ?? AppColors.brand50,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              AppIcon(icon!, size: 12, color: fg ?? AppColors.brand),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: kFontFamily,
                fontFamilyFallback: kFontFallback,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg ?? AppColors.brand,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      );
}

/// 진행률 바 (얇고 둥근)
class Meter extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const Meter(this.value, {super.key, this.color, this.height = 7});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (c, v, _) => LinearProgressIndicator(
            value: v,
            minHeight: height,
            color: color ?? AppColors.brand,
            backgroundColor: AppColors.line,
          ),
        ),
      );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
}

Future<void> copyToClipboard(BuildContext context, String text,
    {String message = '복사했어요'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) toast(context, message);
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? message,
  String ok = '확인',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted),
          child: const Text('취소'),
        ),
        const SizedBox(width: 4),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size(0, 44))
              : FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () => Navigator.pop(c, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// 바텀시트 공통 껍데기
Future<T?> openSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: AppColors.ink.withValues(alpha: 0.4),
      // 시트 자체가 유리입니다 — 뒤 화면이 비칩니다(widgets/glass.dart).
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom),
        child: GlassSurface(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          child: SafeArea(
            top: false,
            child: Bounded(
              max: 480,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

class SheetHandle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SheetHandle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: AppColors.lineStrong,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: Text(title,
                      style: AppText.cardTitle.copyWith(fontSize: 18))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
        ],
      );
}

String won(int amount) {
  final s = amount.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${amount < 0 ? '-' : ''}$b원';
}
