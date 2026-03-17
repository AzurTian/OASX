part of 'home_script_card.dart';

/// Rich text patterns used to highlight log content.
final List<EasyRichTextPattern> _homeScriptCardLogPatterns = [
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

