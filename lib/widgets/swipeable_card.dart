import 'package:flutter/material.dart';

import 'swipe_badge.dart';

enum SwipeDirection { left, right }

class SwipeCardController {
  _SwipeableCardState? _state;

  void _attach(_SwipeableCardState state) => _state = state;

  void _detach(_SwipeableCardState state) {
    if (identical(_state, state)) _state = null;
  }

  void swipeRight() => _state?.flyOut(SwipeDirection.right);

  void swipeLeft() => _state?.flyOut(SwipeDirection.left);
}

class SwipeableCard extends StatefulWidget {
  const SwipeableCard({
    super.key,
    required this.child,
    required this.onSwiped,
    this.controller,
    this.onProgress,
    this.onTap,
  });

  final Widget child;

  final ValueChanged<SwipeDirection> onSwiped;
  final SwipeCardController? controller;

  final ValueChanged<double>? onProgress;
  final VoidCallback? onTap;

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  static const _thresholdRatio = 0.28;

  static const _flingVelocity = 700.0;

  static const _maxRotation = 0.3;

  late final AnimationController _anim;
  Animation<Offset>? _tween;
  Offset _drag = Offset.zero;
  bool _flyingOut = false;
  SwipeDirection? _exitDirection;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this)
      ..addListener(_onTick)
      ..addStatusListener(_onStatus);
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(SwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _anim.dispose();
    super.dispose();
  }

  double get _threshold => MediaQuery.sizeOf(context).width * _thresholdRatio;

  double get _progress => (_drag.dx / _threshold).clamp(-1.0, 1.0);

  void _onTick() {
    final tween = _tween;
    if (tween == null) return;
    setState(() => _drag = tween.value);
    widget.onProgress?.call(_progress);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_flyingOut) return;

    final direction = _exitDirection!;
    _flyingOut = false;
    _exitDirection = null;
    _tween = null;
    _drag = Offset.zero;
    _anim.value = 0;
    widget.onProgress?.call(0);

    widget.onSwiped(direction);
  }

  void _animateTo(Offset target, Duration duration, Curve curve) {
    _tween = Tween<Offset>(
      begin: _drag,
      end: target,
    ).animate(CurvedAnimation(parent: _anim, curve: curve));
    _anim
      ..duration = duration
      ..value = 0
      ..forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_flyingOut) return;
    if (_anim.isAnimating) _anim.stop();
    setState(() => _drag += details.delta);
    widget.onProgress?.call(_progress);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_flyingOut) return;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final passedDistance = _drag.dx.abs() > _threshold;
    final passedVelocity = velocity.abs() > _flingVelocity;

    if (passedDistance || passedVelocity) {
      final reference = passedVelocity ? velocity : _drag.dx;
      flyOut(reference > 0 ? SwipeDirection.right : SwipeDirection.left);
    } else {
      _animateTo(
        Offset.zero,
        const Duration(milliseconds: 340),
        Curves.easeOutBack,
      );
    }
  }

  void flyOut(SwipeDirection direction) {
    if (_flyingOut || !mounted) return;

    _flyingOut = true;
    _exitDirection = direction;

    final width = MediaQuery.sizeOf(context).width;
    final sign = direction == SwipeDirection.right ? 1.0 : -1.0;
    _animateTo(
      Offset(sign * width * 1.5, _drag.dy - 60),
      const Duration(milliseconds: 300),
      Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final progress = _progress;

    return GestureDetector(
      onTap: widget.onTap,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: (_drag.dx / width) * _maxRotation,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              Positioned(
                top: 34,
                left: 24,
                child: SwipeBadge.favorite(progress: progress),
              ),
              Positioned(
                top: 34,
                right: 24,
                child: SwipeBadge.pass(progress: -progress),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
