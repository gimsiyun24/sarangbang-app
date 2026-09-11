import 'package:flutter/material.dart';

import '../theme.dart';

class SegmentOption<T> {
  final T value;
  final String label;

  /// 칸마다 글씨 크기를 달리하고 싶을 때 (글씨 크기 줄이 미리보기로 씁니다)
  final double? fontSize;

  const SegmentOption(this.value, this.label, {this.fontSize});
}

/// 상자 하나 안에서 파란 상자가 고른 칸으로 미끄러지는 고르개 — 애기애타 SegmentedControl 과 같은 모양.
/// 고른 칸에 체크 표시는 두지 않습니다. 파란 상자가 이미 그 일을 합니다.
class SegmentedControl<T> extends StatelessWidget {
  final List<SegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// 바깥 상자와 파란 상자 사이 간격. 사방 모두 이 값입니다.
  static const _padding = 4.0;

  @override
  Widget build(BuildContext context) {
    final index = options.indexWhere((o) => o.value == value).clamp(0, options.length - 1);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: const Cubic(0.22, 1, 0.36, 1),
                left: index * slot,
                width: slot,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < options.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == index,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(options[i].value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 150),
                                style: AppText.bodyStrong.copyWith(
                                  fontSize: options[i].fontSize ?? 15,
                                  height: 1.3,
                                  color: i == index ? Colors.white : AppColors.inkSoft,
                                ),
                                child: Text(options[i].label, maxLines: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
