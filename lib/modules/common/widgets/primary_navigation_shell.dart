import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/home/index.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/settings/index.dart';
import 'package:oasx/translation/i18n_content.dart';

const double kPrimaryNavigationRailWidth = 80;

class PrimaryNavigationShell extends StatelessWidget {
  const PrimaryNavigationShell({
    super.key,
    required this.routePath,
  });

  final String routePath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedIndex = _selectedIndexForRoute(routePath);
        final showRail = _shouldShowRail(constraints.maxWidth);
        return Scaffold(
          appBar: buildPlatformAppBar(context, routePath: routePath),
          body: showRail
              ? Row(
                  children: [
                    _PrimaryNavigationRail(
                      selectedIndex: selectedIndex,
                      onSelected: _navigateToIndex,
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildContent()),
                  ],
                )
              : _buildContent(),
          bottomNavigationBar: showRail
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _navigateToIndex,
                  destinations: _destinations(),
                ),
        );
      },
    );
  }

  bool _shouldShowRail(double maxWidth) {
    const twoPaneShellWidth = kHomeWorkbenchMinCollectionWidth +
        kHomeWorkbenchMinDetailsWidth +
        kHomeWorkbenchDividerWidth +
        kPrimaryNavigationRailWidth;
    return maxWidth >= twoPaneShellWidth;
  }

  Widget _buildContent() {
    return switch (routePath) {
      '/settings' => const SettingsView(standalone: false),
      _ => const HomeView(standalone: false),
    };
  }

  int _selectedIndexForRoute(String value) {
    return value == '/settings' ? 1 : 0;
  }

  void _navigateToIndex(int index) {
    final nextRoute = index == 1 ? '/settings' : '/home';
    if (Get.currentRoute == nextRoute) {
      return;
    }
    Get.offNamed(nextRoute);
  }

  List<Widget> _destinations() {
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_rounded),
        label: I18n.home.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_rounded),
        label: I18n.setting.tr,
      ),
    ];
  }
}

class _PrimaryNavigationRail extends StatelessWidget {
  const _PrimaryNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_rounded),
          label: Text(I18n.home.tr),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_rounded),
          label: Text(I18n.setting.tr),
        ),
      ],
    );
  }
}
