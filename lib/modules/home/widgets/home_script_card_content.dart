part of 'home_script_card.dart';

extension _HomeScriptCardContent on _HomeScriptCardState {
  /// Starts tracking an interactive content flip drag.
  void _handleContentDragStart(DragStartDetails _) {
    _isContentDragActive = true;
    _contentFlipController.stop();
  }

  /// Updates the interactive content flip based on drag distance.
  void _handleContentDragUpdate(DragUpdateDetails details, double width) {
    if (!_isContentDragActive || width <= 0) {
      return;
    }
    final delta = details.delta.dx / width;
    if (_contentFlipController.value <= 0 && delta <= 0) {
      return;
    }
    final nextValue =
        (_contentFlipController.value + delta).clamp(0.0, 1.0);
    _contentFlipController.value = nextValue;
  }

  /// Ends the drag and decides whether to complete or revert the flip.
  void _handleContentDragEnd(DragEndDetails _) {
    _isContentDragActive = false;
    final target = _contentFlipController.value >= 0.5 ? 1.0 : 0.0;
    _animateContentFlipTo(target);
  }

  /// Cancels the drag and reverts the flip.
  void _handleContentDragCancel() {
    _isContentDragActive = false;
    _animateContentFlipTo(0.0);
  }

  /// Animates the flip controller to the target value.
  Future<void> _animateContentFlipTo(double target) async {
    if (_contentFlipController.value == target) {
      if (target >= 1) {
        _finalizeContentFlip();
      }
      return;
    }
    final useDuration = target >= _contentFlipController.value
        ? _HomeScriptCardState._contentFlipDuration
        : _HomeScriptCardState._contentFlipReverseDuration;
    await _contentFlipController.animateTo(
      target,
      duration: useDuration,
      curve: Curves.easeOut,
    );
    if (!mounted) {
      return;
    }
    if (target >= 1) {
      _finalizeContentFlip();
    }
  }

  /// Finalizes the content flip by switching the visible view mode.
  void _finalizeContentFlip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _dashboardController.toggleCardViewMode(widget.scriptModel.name);
      _contentFlipController.value = 0;
    });
  }

  /// Builds the flip transform for the active child.
  Widget _buildFlipTransform({
    required double angle,
    required bool isUnder,
    required Widget child,
  }) {
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateY(angle);
    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: isUnder
          ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: child,
            )
          : child,
    );
  }
}


