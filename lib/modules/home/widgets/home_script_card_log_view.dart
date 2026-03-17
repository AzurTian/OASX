part of 'home_script_card.dart';

/// Log list view used in the home script card content area.
class HomeScriptCardLogView extends StatefulWidget {
  const HomeScriptCardLogView({
    super.key,
    required this.scriptName,
  });

  /// Script name used to resolve the log controller.
  final String scriptName;

  @override
  State<HomeScriptCardLogView> createState() => _HomeScriptCardLogViewState();
}

class _HomeScriptCardLogViewState extends State<HomeScriptCardLogView> {
  /// Manages log data for the current script.
  late final OverviewController _logController;
  /// Scroll controller for the log list.
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _logController = _getOrCreateLogController(widget.scriptName);
    _scrollController = ScrollController(
      initialScrollOffset: _logController.savedScrollOffsetVal,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _restoreInitialScroll();
    });
    _logController.scrollLogs = _scrollLogs;
  }

  @override
  void deactivate() {
    _saveScrollOffset();
    super.deactivate();
  }

  @override
  void dispose() {
    _saveScrollOffset();
    _scrollController?.dispose();
    _scrollController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: _buildLogList(context),
    );
  }
}
