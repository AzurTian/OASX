// ignore_for_file: invalid_use_of_protected_member
part of settings;

extension _SettingsViewNavigation on _SettingsViewState {
  void _handleLeaveSettings() {
    if (_hasHandledLeave) {
      return;
    }
    _hasHandledLeave = true;
    if (!Get.isRegistered<SettingsController>()) {
      return;
    }
    final settingsController = Get.find<SettingsController>();
    if (!settingsController.consumeLoginConfigChanged()) {
      return;
    }
    if (!Get.isRegistered<HomeDashboardController>()) {
      return;
    }
    unawaited(
      Get.find<HomeDashboardController>().refreshAfterSettingsChanged(),
    );
  }

  void _handleScroll() {
    if (_isAutoScrolling || _lockSelectionToClickedNav || !mounted) return;
    _syncSelectedSectionByViewport();
  }

  void _syncSelectedSectionByViewport() {
    final sectionIndex = _findCurrentSectionIndex();
    if (sectionIndex == _selectedSectionIndex) return;
    setState(() => _selectedSectionIndex = sectionIndex);
  }

  int? _findCurrentSectionIndex() {
    final viewportContext = _scrollViewKey.currentContext;
    if (viewportContext == null) return _selectedSectionIndex;

    final viewportRenderObject = viewportContext.findRenderObject();
    if (viewportRenderObject is! RenderBox || !viewportRenderObject.hasSize) {
      return _selectedSectionIndex;
    }

    final viewportTop = viewportRenderObject.localToGlobal(Offset.zero).dy;
    int? passedTopSectionIndex;
    int? upcomingSectionIndex;
    var nearestUpcomingTop = double.infinity;

    for (var index = 0; index < _sections.length; index++) {
      final sectionContext = _sections[index].key.currentContext;
      if (sectionContext == null) continue;
      final sectionRenderObject = sectionContext.findRenderObject();
      if (sectionRenderObject is! RenderBox || !sectionRenderObject.hasSize) {
        continue;
      }

      final sectionTop =
          sectionRenderObject.localToGlobal(Offset.zero).dy - viewportTop;
      if (sectionTop <= _SettingsViewState._topAlignmentTolerance) {
        passedTopSectionIndex = index;
        continue;
      }
      if (sectionTop < nearestUpcomingTop) {
        nearestUpcomingTop = sectionTop;
        upcomingSectionIndex = index;
      }
    }

    return passedTopSectionIndex ?? upcomingSectionIndex ?? _selectedSectionIndex;
  }

  Future<void> _scrollToSection(int index) async {
    if (index < 0 || index >= _sections.length) return;

    final targetContext = _sections[index].key.currentContext;
    if (targetContext == null) return;

    setState(() {
      _selectedSectionIndex = index;
      _lockSelectionToClickedNav = true;
    });

    _isAutoScrolling = true;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
    _isAutoScrolling = false;
  }

  Widget _buildSettingList() {
    return Scrollbar(
      controller: _scrollController,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (_isAutoScrolling || !mounted) return false;
          if (notification.direction != ScrollDirection.idle &&
              _lockSelectionToClickedNav) {
            setState(() => _lockSelectionToClickedNav = false);
          }
          return false;
        },
        child: SingleChildScrollView(
          key: _scrollViewKey,
          controller: _scrollController,
          child: Column(
            children: _sections
                .map(
                  (section) => Container(
                    key: section.key,
                    margin: const EdgeInsets.only(bottom: _SettingsViewState._layoutSpacing),
                    child: section.cardBuilder(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryNav() {
    return SizedBox(
      width: _SettingsViewState._navWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_sections.length, (index) {
              final isSelected = index == _selectedSectionIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _scrollToSection(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.38)
                          : Colors.transparent,
                    ),
                    child: Text(
                      _sections[index].navTitleBuilder(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SettingsSection {
  _SettingsSection({
    required this.key,
    required this.navTitleBuilder,
    required this.cardBuilder,
  });

  final GlobalKey key;
  final String Function() navTitleBuilder;
  final Widget Function() cardBuilder;
}


