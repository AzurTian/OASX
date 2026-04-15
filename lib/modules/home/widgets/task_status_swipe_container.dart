import 'package:flutter/material.dart';

/// Provides the local swipe-to-disable interaction for one overview task row.
class TaskStatusSwipeContainer extends StatefulWidget {
  const TaskStatusSwipeContainer({
    super.key,
    required this.child,
    required this.onConfirmDismiss,
    required this.onDismissed,
    this.background = const SizedBox.expand(),
    this.enabled = true,
  });

  final Widget child;
  final Widget background;
  final Future<bool> Function() onConfirmDismiss;
  final VoidCallback onDismissed;
  final bool enabled;

  @override
  State<TaskStatusSwipeContainer> createState() =>
      _TaskStatusSwipeContainerState();
}

class _TaskStatusSwipeContainerState extends State<TaskStatusSwipeContainer> {
  static const Duration _settleDuration = Duration(milliseconds: 180);
  static const double _dismissThreshold = 0.5;
  static const double _leftEdgeThreshold = 0.98;

  bool _isDragging = false;
  bool _isSubmitting = false;
  double _slideFraction = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return IgnorePointer(
          ignoring: _isSubmitting,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _handleDragStart(),
            onHorizontalDragUpdate: (details) =>
                _handleDragUpdate(details, width),
            onHorizontalDragCancel: _handleDragCancel,
            onHorizontalDragEnd: (_) => _handleDragEnd(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(child: widget.background),
                  AnimatedSlide(
                    offset: Offset(_slideFraction, 0),
                    duration: _isDragging ? Duration.zero : _settleDuration,
                    curve: Curves.easeOutCubic,
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Records one active swipe session.
  void _handleDragStart() {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isDragging = true;
    });
  }

  /// Updates the row offset while the user keeps dragging left.
  void _handleDragUpdate(DragUpdateDetails details, double width) {
    if (_isSubmitting || width <= 0) {
      return;
    }
    final nextOffset = _slideFraction + (details.delta.dx / width);
    setState(() {
      _slideFraction = nextOffset.clamp(-1.0, 0.0);
    });
  }

  /// Resets the row when one drag session gets cancelled by the gesture arena.
  void _handleDragCancel() {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isDragging = false;
      _slideFraction = 0;
    });
  }

  /// Resolves threshold logic, dismissal confirmation, and the final slide-out.
  Future<void> _handleDragEnd() async {
    if (_isSubmitting) {
      return;
    }
    if (_slideFraction.abs() <= _dismissThreshold) {
      setState(() {
        _isDragging = false;
        _slideFraction = 0;
      });
      return;
    }
    setState(() {
      _isDragging = false;
      _isSubmitting = true;
    });
    var confirmed = false;
    try {
      confirmed = await widget.onConfirmDismiss();
    } catch (_) {}
    if (!mounted) {
      return;
    }
    if (!confirmed) {
      setState(() {
        _isSubmitting = false;
        _slideFraction = 0;
      });
      return;
    }
    final reachedLeftEdge = _slideFraction.abs() >= _leftEdgeThreshold;
    if (!reachedLeftEdge) {
      setState(() {
        _slideFraction = -1;
      });
      await Future<void>.delayed(_settleDuration);
      if (!mounted) {
        return;
      }
    }
    widget.onDismissed();
  }
}
