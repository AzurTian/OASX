import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:window_manager/window_manager.dart';

import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/modules/common/widgets/title.dart';

/// Unified entry: build app bar by platform.
PreferredSizeWidget buildPlatformAppBar(
  BuildContext context, {
  bool isCollapsed = false,
  VoidCallback? onMenuPressed,
  String? routePath,
  List<Widget> trailingActions = const [],
}) {
  final platform = PlatformUtils.platfrom();
  return switch (platform) {
    PlatformType.windows => _windowAppbar(
        context,
        onMenuPressed: isCollapsed ? onMenuPressed : null,
        routePath: routePath,
        trailingActions: trailingActions,
      ),
    PlatformType.linux => _desktopAppbar(
        context,
        routePath: routePath,
        trailingActions: trailingActions,
      ),
    PlatformType.macOS => _desktopAppbar(
        context,
        routePath: routePath,
        trailingActions: trailingActions,
      ),
    PlatformType.android => _mobileTabletAppbar(context, routePath: routePath),
    PlatformType.iOS => _mobileTabletAppbar(context, routePath: routePath),
    PlatformType.web => _webAppbar(
        context,
        routePath: routePath,
        trailingActions: trailingActions,
      ),
    _ => _webAppbar(
        context,
        routePath: routePath,
        trailingActions: trailingActions,
      ),
  };
}

/// Windows specific title bar.
PreferredSizeWidget _windowAppbar(
  BuildContext context, {
  VoidCallback? onMenuPressed,
  String? routePath,
  List<Widget> trailingActions = const [],
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(50),
    child: WindowCaption(
      brightness: Theme.of(context).brightness,
      backgroundColor: Colors.transparent,
      title: _buildWindowTitle(
        context,
        onMenuPressed: onMenuPressed,
        routePath: routePath,
        trailingActions: trailingActions,
      ),
    ),
  );
}

/// Desktop (Linux / macOS)
PreferredSizeWidget _desktopAppbar(
  BuildContext context, {
  String? routePath,
  List<Widget> trailingActions = const [],
}) {
  return AppBar(
    title: getTitle(context, routePath: routePath),
    automaticallyImplyLeading: _shouldAutoImplyLeading(routePath),
    actions: trailingActions.isEmpty ? null : trailingActions,
  );
}

/// Web
PreferredSizeWidget _webAppbar(
  BuildContext context, {
  String? routePath,
  List<Widget> trailingActions = const [],
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(90),
    child: Row(
      children: [
        Expanded(
          child: getTitle(context, routePath: routePath)
              .padding(left: 16, top: 10, bottom: 10),
        ),
        ...trailingActions,
        if (trailingActions.isNotEmpty) const SizedBox(width: 8),
      ],
    ),
  );
}

/// Mobile (Android / iOS)
PreferredSizeWidget _mobileTabletAppbar(
  BuildContext context, {
  String? routePath,
}) {
  return AppBar(
    title: getTitle(context, routePath: routePath),
    automaticallyImplyLeading: _shouldAutoImplyLeading(routePath),
  );
}

bool _shouldAutoImplyLeading(String? routePath) => routePath != '/overview';

Widget _buildWindowTitle(
  BuildContext context, {
  VoidCallback? onMenuPressed,
  String? routePath,
  List<Widget> trailingActions = const [],
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (onMenuPressed != null)
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: onMenuPressed,
        ),
      Flexible(
        fit: FlexFit.loose,
        child: getTitle(context, routePath: routePath),
      ),
      ...trailingActions,
    ],
  );
}

