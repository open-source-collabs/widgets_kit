import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:widgets_kit/widgets_kit.dart';

/// Runs the plugin against the real macOS implementation:
/// `flutter test integration_test/macos_test.dart -d macos`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const group = 'group.com.widgetskit.integrationTest';

  setUpAll(() async {
    await WidgetsKit.setAppGroupId(group);
  });

  testWidgets('macOS reports home screen widgets as supported', (_) async {
    expect(Platform.isMacOS, isTrue);
    expect(WidgetsKit.isSupported, isTrue);
  });

  testWidgets('saved data is read back with its type', (_) async {
    expect(await WidgetsKit.saveWidgetData<String>('title', 'Hello'), isTrue);
    expect(await WidgetsKit.saveWidgetData<int>('count', 7), isTrue);
    expect(await WidgetsKit.saveWidgetData<double>('price', 12.5), isTrue);
    expect(await WidgetsKit.saveWidgetData<bool>('on', true), isTrue);

    expect(await WidgetsKit.getWidgetData<String>('title'), 'Hello');
    expect(await WidgetsKit.getWidgetData<int>('count'), 7);
    expect(await WidgetsKit.getWidgetData<double>('price'), 12.5);
    expect(await WidgetsKit.getWidgetData<bool>('on'), true);
  });

  testWidgets('saving null removes the value', (_) async {
    await WidgetsKit.saveWidgetData<String>('gone', 'x');
    await WidgetsKit.saveWidgetData<String>('gone', null);

    expect(
      await WidgetsKit.getWidgetData<String>('gone', defaultValue: 'fallback'),
      'fallback',
    );
  });

  testWidgets('updateWidget asks WidgetKit to reload', (_) async {
    expect(await WidgetsKit.updateWidget(name: 'ExampleWidget'), isTrue);
  });

  testWidgets('installed widgets can be listed', (_) async {
    expect(await WidgetsKit.getInstalledWidgets(), isA<List<WidgetsKitInfo>>());
  });
}
