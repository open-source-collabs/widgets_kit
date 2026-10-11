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
  const integrationAppGroupId = 'group.com.widgetskit.integrationTest';

  group('Need Group Id', () {
    testWidgets('Save Data needs GroupId', (tester) async {
      expect(
        () async => await WidgetsKit.saveWidgetData('AnyId', null),
        throwsException,
      );
    });
  });

  group('With Group Id', () {
    final testData = <String, dynamic>{
      'stringKey': 'stringValue',
      'intKey': 12,
      'boolKey': true,
      'floatingNumberKey': 12.1,
      'nullValueKey': null,
      'uint8ListKey': Uint8List.fromList([]),
      'largeDoubleKey': double.infinity,
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
      // Add Group Id
      await WidgetsKit.setAppGroupId(integrationAppGroupId);
      // Clear all Data
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

    testWidgets('Update Widget completes', (tester) async {
      final returnValue = await WidgetsKit.updateWidget(
        name: 'WidgetsKitExampleProvider',
        iOSName: 'WidgetsKitExample',
      ).timeout(const Duration(seconds: 5));

      expect(returnValue, true);
    });

    group('Update Widget with single arguments', () {
      testWidgets('Update Widget with name only', (tester) async {
        final returnValue = await WidgetsKit.updateWidget(
          name: 'WidgetsKitExample',
        ).timeout(const Duration(seconds: 5));

        expect(returnValue, true);
      });

      testWidgets('Update Widget with iOSName only', (tester) async {
        final returnValue = await WidgetsKit.updateWidget(
          iOSName: 'WidgetsKitExample',
        ).timeout(const Duration(seconds: 5));

        expect(returnValue, true);
      });
    });

    testWidgets('Update Widget Preview returns false', (tester) async {
      final returnValue = await WidgetsKit.updateWidgetPreview(
        name: 'WidgetsKitExample',
      ).timeout(const Duration(seconds: 5));

      expect(returnValue, false);
    });

    group('Initially Launched', () {
      testWidgets(
        'Initially Launched completes and returns null if not launched from widget',
        (tester) async {
          await WidgetsKit.setAppGroupId(integrationAppGroupId);
          final retrievedData =
              await WidgetsKit.initiallyLaunchedFromWidgetsKit();
          expect(retrievedData, isNull);
        },
      );

      group('Register Background Callback', () {
        testWidgets('RegisterBackgroundCallback completes without error', (
          tester,
        ) async {
          final deviceInfo = await DeviceInfoPlugin().iosInfo;
          final hasInteractiveWidgets =
              double.parse(deviceInfo.systemVersion.split('.').first) >= 17.0;
          await WidgetsKit.setAppGroupId(integrationAppGroupId);
          if (hasInteractiveWidgets) {
            final registerCallbackResult =
                await WidgetsKit.registerInteractivityCallback(
                  interactivityCallback,
                );

            expect(registerCallbackResult, isTrue);
          } else {
            expect(
              () async => await WidgetsKit.registerInteractivityCallback(
                interactivityCallback,
              ),
              throwsA(isA<PlatformException>()),
            );
          }
        });
      });
    });
  });

  testWidgets('Get Installed Widgets returns empty list', (tester) async {
    final retrievedData = await WidgetsKit.getInstalledWidgets();
    expect(retrievedData, isEmpty);
  });

  group('Android Configurable Widgets', () {
    testWidgets('Android-specific APIs complete on iOS stubs', (tester) async {
      await WidgetsKit.setAppGroupId(integrationAppGroupId);
      await expectLater(
        WidgetsKit.isRequestPinWidgetSupported(),
        completion(false),
      );

      await expectLater(
        WidgetsKit.requestPinWidget(name: 'WidgetsKitExample'),
        completes,
      );

      await expectLater(
        WidgetsKit.initiallyLaunchedFromWidgetsKitConfigure(),
        completion(isNull),
      );

      await expectLater(WidgetsKit.finishWidgetsKitConfigure(), completes);
    });
  });

  group('Per-call app group without global setup', () {
    const keyValueKey = 'integration_per_call_key';
    const fileKey = 'integration_per_call_file_key';

    setUp(() async {
      WidgetsKit.groupId = null;
      await WidgetsKit.saveWidgetData(
        keyValueKey,
        null,
        appGroupId: integrationAppGroupId,
      );
      await WidgetsKit.saveWidgetData(
        fileKey,
        null,
        appGroupId: integrationAppGroupId,
      );
    });

    testWidgets('save/get widget data with appGroupId override', (
      tester,
    ) async {
      await WidgetsKit.saveWidgetData(
        keyValueKey,
        'value',
        appGroupId: integrationAppGroupId,
      );

      final value = await WidgetsKit.getWidgetData<String>(
        keyValueKey,
        appGroupId: integrationAppGroupId,
      );
      expect(value, 'value');
    });

    testWidgets('saveFile and clear with appGroupId override', (tester) async {
      final path = await WidgetsKit.saveFile(
        fileKey,
        Uint8List.fromList(utf8.encode(jsonEncode({'per': 'call'}))),
        extension: 'json',
        appGroupId: integrationAppGroupId,
      );
      expect(await File(path).exists(), isTrue);

      final storedPath = await WidgetsKit.getWidgetData<String>(
        fileKey,
        appGroupId: integrationAppGroupId,
      );
      expect(storedPath, path);

      await WidgetsKit.saveWidgetData(
        fileKey,
        null,
        appGroupId: integrationAppGroupId,
      );
      expect(
        await WidgetsKit.getWidgetData<String>(
          fileKey,
          appGroupId: integrationAppGroupId,
        ),
        isNull,
      );
      expect(await File(path).exists(), isFalse);
    });
  });
}

Future<void> interactivityCallback(Uri? uri) async {}
