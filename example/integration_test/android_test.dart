import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_kit/widgets_kit.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final testData = <String, dynamic>{
    'stringKey': 'stringValue',
    'intKey': 12,
    'boolKey': true,
    'floatingNumberKey': 12.1,
    'largeDoubleKey': double.infinity,
    'nullValueKey': null,
    'longKey': DateTime(2024).millisecondsSinceEpoch,
  };

  final cleanupKeys = <String>{
    ...testData.keys,
    'integration_json_file_key',
    'integration_png_file_key',
    'integration_save_image_key',
    'integration_savefile_clear_key',
    'integration_savefile_clear_no_delete_key',
  };

  const defaultValue = MapEntry('defaultKey', 'defaultValue');

  setUp(() async {
    for (final key in cleanupKeys) {
      await WidgetsKit.saveWidgetData(key, null);
    }
  });

  group('Test Data operations', () {
    for (final testSet in testData.entries) {
      testWidgets('Test ${testSet.key}', (tester) async {
        // Save Data
        await WidgetsKit.saveWidgetData(testSet.key, testSet.value);

        final retrievedData = await WidgetsKit.getWidgetData(testSet.key);
        expect(retrievedData, testSet.value);
      });
    }

    testWidgets('Delete Value successful', (tester) async {
      final entry = testData.entries.first;
      final key = entry.key;
      final value = entry.value;

      await WidgetsKit.saveWidgetData(key, value);
      expect(await WidgetsKit.getWidgetData(key), value);

      await WidgetsKit.saveWidgetData(key, null);

      expect(await WidgetsKit.getWidgetData(key), isNull);
    });

    testWidgets('Returns default Value', (tester) async {
      final returnValue = await WidgetsKit.getWidgetData(
        defaultValue.key,
        defaultValue: defaultValue.value,
      );

      expect(returnValue, defaultValue.value);
    });
  });

  testWidgets('Update Widget completes', (tester) async {
    final returnValue = await WidgetsKit.updateWidget(
      name: 'WidgetsKitExampleProvider',
    ).timeout(const Duration(seconds: 5));

    expect(returnValue, true);
  });

  group('Update Widget with single arguments', () {
    testWidgets('Update Widget with name only', (tester) async {
      final returnValue = await WidgetsKit.updateWidget(
        name: 'WidgetsKitExampleProvider',
      ).timeout(const Duration(seconds: 5));

      expect(returnValue, true);
    });

    testWidgets('Update Widget with androidName only', (tester) async {
      final returnValue = await WidgetsKit.updateWidget(
        androidName: 'WidgetsKitExampleProvider',
      ).timeout(const Duration(seconds: 5));

      expect(returnValue, true);
    });

    testWidgets('Update Widget with qualifiedAndroidName only', (tester) async {
      final returnValue = await WidgetsKit.updateWidget(
        qualifiedAndroidName:
            'com.widgetskit.widgets_kit_example.WidgetsKitExampleProvider',
      ).timeout(const Duration(seconds: 5));

      expect(returnValue, true);
    });
  });

  group('Update Widget Preview', () {
    const glanceReceiverClassName = 'glance.WidgetsKitReceiver';
    const qualifiedGlanceReceiverName =
        'com.widgetskit.widgets_kit_example.$glanceReceiverClassName';

    // The system accepts about two previews per hour and Widget, so only the
    // first of these tests can expect a preview to be accepted.
    testWidgets('Update Widget Preview with qualifiedAndroidName', (
      tester,
    ) async {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

      final returnValue = await WidgetsKit.updateWidgetPreview(
        qualifiedAndroidName: qualifiedGlanceReceiverName,
      ).timeout(const Duration(seconds: 10));

      expect(returnValue, sdkInt < 35 ? false : true);
    });

    testWidgets('Update Widget Preview with androidName only', (tester) async {
      final returnValue = await WidgetsKit.updateWidgetPreview(
        androidName: glanceReceiverClassName,
      ).timeout(const Duration(seconds: 10));

      expect(returnValue, isA<bool>());
    });

    testWidgets('Update Widget Preview with name only', (tester) async {
      final returnValue = await WidgetsKit.updateWidgetPreview(
        name: glanceReceiverClassName,
      ).timeout(const Duration(seconds: 10));

      expect(returnValue, isA<bool>());
    });

    testWidgets('Update Widget Preview of a non Glance Widget returns false', (
      tester,
    ) async {
      final returnValue = await WidgetsKit.updateWidgetPreview(
        qualifiedAndroidName:
            'com.widgetskit.widgets_kit_example.WidgetsKitExampleProvider',
      ).timeout(const Duration(seconds: 10));

      expect(returnValue, false);
    });

    testWidgets('Update Widget Preview of an unknown Widget throws', (
      tester,
    ) async {
      await expectLater(
        WidgetsKit.updateWidgetPreview(name: 'UnknownWidgetReceiver'),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', '-8')),
      );
    });
  });

  testWidgets('Register Background Callback', (tester) async {
    final returnValue = await WidgetsKit.registerInteractivityCallback(
      backgroundCallback,
    );
    expect(returnValue, true);
  });

  testWidgets(
    'Initially Launched completes and returns null if not launched from widget',
    (tester) async {
      final retrievedData = await WidgetsKit.initiallyLaunchedFromWidgetsKit();
      expect(retrievedData, isNull);
    },
  );

  testWidgets('Get Installed Widgets returns empty list', (tester) async {
    final retrievedData = await WidgetsKit.getInstalledWidgets();
    expect(retrievedData, isEmpty);
  });

  group('saveFile and saveImage', () {
    testWidgets('saveFile JSON round-trip', (tester) async {
      const key = 'integration_json_file_key';
      final data = <String, dynamic>{'hello': 'world', 'n': 42};
      final jsonStr = jsonEncode(data);
      final path = await WidgetsKit.saveFile(
        key,
        Uint8List.fromList(utf8.encode(jsonStr)),
        extension: 'json',
      );
      final storedPath = await WidgetsKit.getWidgetData<String>(key);
      expect(storedPath, path);
      final read = jsonDecode(await File(path).readAsString());
      expect(read, data);
    });

    testWidgets('saveFile PNG bytes match asset', (tester) async {
      const key = 'integration_png_file_key';
      final bundle = await rootBundle.load('assets/integration_test.png');
      final expected = bundle.buffer.asUint8List();
      final path = await WidgetsKit.saveFile(key, expected, extension: 'png');
      final storedPath = await WidgetsKit.getWidgetData<String>(key);
      expect(storedPath, path);
      final read = await File(path).readAsBytes();
      expect(read, orderedEquals(expected));
    });

    testWidgets('saveImage decodes asset and saves valid 1x1 PNG', (
      tester,
    ) async {
      const key = 'integration_save_image_key';
      final path = await WidgetsKit.saveImage(
        key,
        const AssetImage('assets/integration_test.png'),
      );
      final storedPath = await WidgetsKit.getWidgetData<String>(key);
      expect(storedPath, path);
      final bytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1);
      expect(frame.image.height, 1);
    });

    testWidgets('saveFile then clear key removes data and file', (
      tester,
    ) async {
      const key = 'integration_savefile_clear_key';
      final data = <String, dynamic>{'clear': 'test'};
      final jsonStr = jsonEncode(data);
      final path = await WidgetsKit.saveFile(
        key,
        Uint8List.fromList(utf8.encode(jsonStr)),
        extension: 'json',
      );
      expect(await File(path).exists(), isTrue);
      await WidgetsKit.saveWidgetData(key, null);
      expect(await WidgetsKit.getWidgetData(key), isNull);
      expect(await File(path).exists(), isFalse);
    });

    testWidgets(
      'saveFile then clear key with deleteFile false removes path but keeps file',
      (tester) async {
        const key = 'integration_savefile_clear_no_delete_key';
        final data = <String, dynamic>{'keep': 'on_disk'};
        final jsonStr = jsonEncode(data);
        final path = await WidgetsKit.saveFile(
          key,
          Uint8List.fromList(utf8.encode(jsonStr)),
          extension: 'json',
        );
        expect(await File(path).exists(), isTrue);
        await WidgetsKit.saveWidgetData(key, null, deleteFile: false);
        expect(await WidgetsKit.getWidgetData(key), isNull);
        expect(await File(path).exists(), isTrue);
        expect(jsonDecode(await File(path).readAsString()), data);
      },
    );
  });
}

Future<void> backgroundCallback(Uri? uri) async {}
