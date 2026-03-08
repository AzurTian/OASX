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
}) {
  final platform = PlatformUtils.platfrom();
  return switch (platform) {
    PlatformType.windows => _windowAppbar(
        context,
        onMenuPressed: isCollapsed ? onMenuPressed : null,
        routePath: routePath,
      ),
    PlatformType.linux => _desktopAppbar(context, routePath: routePath),
    PlatformType.macOS => _desktopAppbar(context, routePath: routePath),
    PlatformType.android => _mobileTabletAppbar(context, routePath: routePath),
    PlatformType.iOS => _mobileTabletAppbar(context, routePath: routePath),
    PlatformType.web => _webAppbar(context, routePath: routePath),
    _ => _webAppbar(context, routePath: routePath),
  };
}

/// Windows specific title bar.
PreferredSizeWidget _windowAppbar(
  BuildContext context, {
  VoidCallback? onMenuPressed,
  String? routePath,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(50),
    child: WindowCaption(
      brightness: Theme.of(context).brightness,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          if (onMenuPressed != null)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            ),
          getTitle(context, routePath: routePath),
        ],
      ),
    ),
  );
}

/// Desktop (Linux / macOS)
PreferredSizeWidget _desktopAppbar(BuildContext context, {String? routePath}) {
  return AppBar(
    title: getTitle(context, routePath: routePath),
    automaticallyImplyLeading: _shouldAutoImplyLeading(routePath),
  );
}

/// Web
PreferredSizeWidget _webAppbar(BuildContext context, {String? routePath}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(90),
    child: getTitle(context, routePath: routePath)
        .padding(left: 16, top: 10, bottom: 10),
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

