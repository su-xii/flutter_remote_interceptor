import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remote_interceptor/providers/theme_provider.dart';

class HitCounterWidget extends ConsumerStatefulWidget {
  final int hitCount;
  final bool shouldAnimate;

  const HitCounterWidget({
    super.key,
    required this.hitCount,
    this.shouldAnimate = false,
  });

  @override
  ConsumerState<HitCounterWidget> createState() => _HitCounterWidgetState();
}

class _HitCounterWidgetState extends ConsumerState<HitCounterWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _opacityAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 70),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    final colors = ref.read(themeProvider);
    _colorAnimation = ColorTweenSequence([
      ColorTweenSequenceItem(tween: ColorTween(begin: colors.textSecondary, end: colors.primary), weight: 50),
      ColorTweenSequenceItem(tween: ColorTween(begin: colors.primary, end: colors.textSecondary), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.shouldAnimate) {
      _triggerAnimation();
    }
  }

  @override
  void didUpdateWidget(HitCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hitCount > oldWidget.hitCount) {
      _triggerAnimation();
    }
  }

  void _triggerAnimation() {
    setState(() {
      _isAnimating = true;
    });
    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeProvider);

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _colorAnimation, _opacityAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _isAnimating
                  ? colors.primary.withOpacity(0.15)
                  : colors.textSecondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isAnimating
                    ? colors.primary.withOpacity(0.3)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 14,
                  color: _isAnimating
                      ? colors.primary
                      : colors.textSecondary.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  "命中 ${widget.hitCount} 次",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _isAnimating
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: _colorAnimation.value,
                  ),
                ),
                AnimatedBuilder(
                  animation: _opacityAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: _isAnimating
                          ? Row(
                        children: const [
                          SizedBox(width: 4),
                          Text(
                            '+1',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ColorTweenSequenceItem {
  final ColorTween tween;
  final int weight;

  ColorTweenSequenceItem({
    required this.tween,
    required this.weight,
  });
}

class ColorTweenSequence extends Animatable<Color?> {
  final List<ColorTweenSequenceItem> items;

  ColorTweenSequence(this.items);

  @override
  Color? transform(double t) {
    double cumulativeWeight = 0.0;
    double totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemStart = cumulativeWeight / totalWeight;
      final itemEnd = (cumulativeWeight + item.weight) / totalWeight;

      if (t <= itemEnd || i == items.length - 1) {
        final localT = (t - itemStart) / (itemEnd - itemStart);
        return item.tween.transform(localT.clamp(0.0, 1.0));
      }
      cumulativeWeight += item.weight;
    }
    return null;
  }
}
