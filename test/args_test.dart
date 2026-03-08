import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/args/index.dart';

void main() {
  test('ArgsController can load model from json string', () {
    const payload =
        '{"scheduler":[{"name":"enable","value":true,"type":"boolean"}]}';
    final controller = ArgsController();
    controller.loadModelfromStr(payload);

    expect(controller.groups.value.length, 1);
    expect(controller.groups.value.first.groupName, 'scheduler');
  });
}
