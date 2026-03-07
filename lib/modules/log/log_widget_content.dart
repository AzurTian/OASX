part of 'log_widget.dart';

class LogContent extends StatelessWidget {
  const LogContent({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.onUserScroll,
  });

  final LogMixin controller;
  final ScrollController scrollController;
  final Function() onUserScroll;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          onUserScroll();
          return false;
        },
        child: Obx(
          () => ListView.builder(
            controller: scrollController,
            itemCount: controller.logs.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: EasyRichText(
                controller.logs[index],
                patternList: _buildPatterns(),
                selectable: true,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                defaultStyle: _selectStyle(context),
              ),
            ),
          ).paddingAll(10),
        ),
      ),
    ).constrained(width: double.infinity, height: double.infinity);
  }

  List<EasyRichTextPattern> _buildPatterns() {
    return [
      const EasyRichTextPattern(
        targetString: 'INFO',
        style: TextStyle(
          color: Color.fromARGB(255, 55, 109, 136),
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        suffixInlineSpan: TextSpan(
          style: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          text: '      ',
        ),
      ),
      const EasyRichTextPattern(
        targetString: 'WARNING',
        style: TextStyle(
          color: Colors.yellow,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const EasyRichTextPattern(
        targetString: 'ERROR',
        style: TextStyle(
          color: Colors.red,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        suffixInlineSpan: TextSpan(
          style: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          text: '    ',
        ),
      ),
      const EasyRichTextPattern(
        targetString: 'CRITICAL',
        style: TextStyle(
          color: Colors.red,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        suffixInlineSpan: TextSpan(text: '   '),
      ),
      const EasyRichTextPattern(
        targetString: r'(\d{2}:\d{2}:\d{2}\.\d{3})',
        style: TextStyle(
          color: Colors.cyan,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const EasyRichTextPattern(
        targetString: r'[\{\[\(\)\]\}]',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const EasyRichTextPattern(
        targetString: 'True',
        style: TextStyle(color: Colors.lightGreen),
      ),
      const EasyRichTextPattern(
        targetString: 'False',
        style: TextStyle(color: Colors.red),
      ),
      const EasyRichTextPattern(
        targetString: 'None',
        style: TextStyle(color: Colors.purple),
      ),
      const EasyRichTextPattern(
        targetString: r'(某喵*某喵)|(~~*~~)',
        style: TextStyle(color: Colors.lightGreen),
      ),
    ];
  }

  TextStyle _selectStyle(BuildContext context) {
    return context.mediaQuery.orientation == Orientation.portrait
        ? Theme.of(context).textTheme.bodySmall!
        : Theme.of(context).textTheme.titleSmall!;
  }
}
