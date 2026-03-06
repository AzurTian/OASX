import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:window_manager/window_manager.dart';

import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/layout/title.dart';

/// Unified entry: build app bar by platform.
PreferredSizeWidget buildPlatformAppBar(
  BuildContext context, {
  bool isCollapsed = false,
  VoidCallback? onMenuPressed,
}) {
  final platform = PlatformUtils.platfrom();
  return switch (platform) {
    PlatformType.windows => _windowAppbar(
        context,
        onMenuPressed: isCollapsed ? onMenuPressed : null,
      ),
    PlatformType.linux => _desktopAppbar(context),
    PlatformType.macOS => _desktopAppbar(context),
    PlatformType.android => _mobileTabletAppbar(context),
    PlatformType.iOS => _mobileTabletAppbar(context),
    PlatformType.web => _webAppbar(context),
    _ => _webAppbar(context),
  };
}

/// Windows specific title bar.
PreferredSizeWidget _windowAppbar(
  BuildContext context, {
  VoidCallback? onMenuPressed,
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
          getTitle(context),
        ],
      ),
    ),
  );
}

/// Desktop (Linux / macOS)
PreferredSizeWidget _desktopAppbar(BuildContext context) {
  return AppBar(title: getTitle(context));
}

/// Web
PreferredSizeWidget _webAppbar(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(90),
    child: getTitle(context).padding(left: 16, top: 10, bottom: 10),
  );
}

/// Mobile (Android / iOS)
PreferredSizeWidget _mobileTabletAppbar(BuildContext context) {
  return AppBar(title: getTitle(context));
}
