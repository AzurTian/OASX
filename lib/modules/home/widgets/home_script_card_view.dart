part of 'home_script_card.dart';

extension _HomeScriptCardView on _HomeScriptCardState {
  Widget _buildCard(BuildContext context) {
    return SizedBox(
      height: homeScriptCardHeight(widget.taskListHeight),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Obx(() {
            final state = widget.scriptModel.state.value;
            final isRunning = state == ScriptState.running;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (widget.showLinkCheckbox)
                      Checkbox(
                        value: widget.isLinked,
                        visualDensity: VisualDensity.compact,
                        onChanged: (value) {
                          widget.onLinkedChanged(value ?? false);
                        },
                      ).paddingOnly(right: 2),
                    IconButton(
                      tooltip: I18n.log.tr,
                      onPressed: widget.onOpenLog,
                      icon: const Icon(Icons.article_outlined),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _startEditingName,
                        onLongPressStart: (_) => _startDeleteHold(),
                        onLongPressEnd: (_) => _cancelDeleteHold(),
                        onLongPressCancel: _cancelDeleteHold,
                        child: _isEditingName
                            ? TextField(
                                controller: _nameController,
                                focusNode: _nameFocusNode,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 8),
                                  border: const OutlineInputBorder(),
                                  enabled: !_isSubmittingRename,
                                ),
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _nameFocusNode.unfocus(),
                              ).paddingSymmetric(vertical: 1, horizontal: 4)
                            : AnimatedBuilder(
                                animation: _deleteHoldController,
                                builder: (context, child) {
                                  final progress = _deleteHoldController.value;
                                  if (progress <= 0) {
                                    return child!;
                                  }
                                  final colorScheme =
                                      Theme.of(context).colorScheme;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      child!,
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: LinearProgressIndicator(
                                          minHeight: 4,
                                          value: progress,
                                          color: colorScheme.error,
                                          backgroundColor: colorScheme.error
                                              .withValues(alpha: 0.20),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                child: Text(
                                  widget.scriptModel.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ).paddingSymmetric(vertical: 3, horizontal: 4),
                              ),
                      ),
                    ),
                    _ScriptStateIndicator(state: state),
                    IconButton(
                      tooltip: isRunning ? I18n.stop.tr : I18n.run.tr,
                      onPressed: () async {
                        await widget.onTogglePower(!isRunning);
                      },
                      icon: const Icon(Icons.power_settings_new_rounded),
                      isSelected: isRunning,
                    ),
                    IconButton(
                      onPressed: _openTaskManager,
                      icon: const Icon(Icons.playlist_add_check_rounded),
                    ),
                  ],
                ),
                const Divider(height: 14),
                SizedBox(
                  height: widget.taskListHeight,
                  child: HomeTaskSummary(
                    scriptModel: widget.scriptModel,
                    onTapList: widget.onTaskListTap,
                    onSetTaskArgument: widget.onSetTaskArgument,
                    onOpenTaskSettings: widget.onOpenTaskSettings,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
