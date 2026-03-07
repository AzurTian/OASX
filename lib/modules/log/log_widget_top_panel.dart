part of 'log_widget.dart';

class TopLogPanel extends StatelessWidget {
  const TopLogPanel({
    super.key,
    required this.controller,
    required this.title,
    this.enableCopy,
    this.enableAutoScroll,
    this.enableClear,
    this.enableCollapse,
    this.bottomChild,
  });

  final LogMixin controller;
  final String title;
  final bool? enableCopy;
  final bool? enableAutoScroll;
  final bool? enableClear;
  final bool? enableCollapse;
  final Widget? bottomChild;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (enableAutoScroll ?? true) _autoScrollButton(),
              if (enableCopy ?? true) _copyButton(),
              if (enableClear ?? true) _deleteButton(),
              if (enableCollapse ?? true) _collapseButton(),
            ],
          ).paddingAll(8).constrained(height: 48),
          if (bottomChild != null) ...[
            const Divider(height: 1),
            bottomChild!,
          ],
        ],
      ),
    );
  }

  Widget _copyButton() {
    return IconButton(
      icon: const Icon(Icons.content_copy_rounded, size: 18),
      onPressed: () => controller.copyLogs(),
    );
  }

  Widget _autoScrollButton() {
    return Obx(
      () => IconButton(
        icon: Icon(
          controller.autoScroll.value ? Icons.flash_on : Icons.flash_off,
          size: 20,
        ),
        onPressed: controller.toggleAutoScroll,
      ),
    );
  }

  Widget _deleteButton() {
    return IconButton(
      icon: const Icon(Icons.delete_outlined, size: 20),
      onPressed: () => controller.clearLog(),
    );
  }

  Widget _collapseButton() {
    return Obx(
      () => IconButton(
        icon: Icon(
          controller.collapseLog.value ? Icons.expand_more : Icons.expand_less,
          size: 20,
        ),
        onPressed: () => controller.toggleCollapse(),
      ),
    );
  }
}
