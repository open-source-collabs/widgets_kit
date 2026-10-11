import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:widgets_kit/widgets_kit.dart';
import 'package:mocktail/mocktail.dart';

// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'mocks.dart';
import 'utils/test_png.dart';

const updateChannel = MethodChannel('widgets_kit/updates');

void main() {
  const channel = MethodChannel('widgets_kit');

  TestWidgetsFlutterBinding.ensureInitialized();

  late Completer<dynamic> passedArguments;

  dynamic launchUri;
  dynamic configureWidgetId;

  setUp(() {
    launchUri = null;
    configureWidgetId = null;
    passedArguments = Completer();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    // ignore: body_might_complete_normally_nullable
    .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      passedArguments.complete(methodCall.arguments);
      switch (methodCall.method) {
        case 'saveWidgetData':
          return true;
        case 'getWidgetData':
          return 'TestData';
        case 'updateWidget':
          return true;
        case 'updateWidgetPreview':
          return true;
        case 'setAppGroupId':
          return true;
        case 'initiallyLaunchedFromWidgetsKit':
          return Future.value(launchUri);
        case 'initiallyLaunchedFromWidgetsKitConfigure':
          return Future.value(configureWidgetId);
        case 'finishWidgetsKitConfigure':
          return null;
        case 'registerBackgroundCallback':
          return true;
        case 'requestPinWidget':
          return null;
        case 'isRequestPinWidgetSupported':
          return true;
        case 'scheduleWidgetUpdates':
          return true;
        case 'cancelScheduledWidgetUpdates':
          return true;
        case 'canScheduleExactWidgetUpdates':
          return true;
      }
      throw UnimplementedError(
        'Method ${methodCall.method} not implemented in mock',
      );
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getWidgetData', () async {
    const dataId = 'TestId';
    expect(await WidgetsKit.getWidgetData<String>(dataId), 'TestData');
    final arguments = await passedArguments.future;

    expect(arguments['id'], dataId);
  });

  test('getWidgetData passes Default Value', () async {
    const dataId = 'TestId';
    const defaultValue = 'Default Value';
    await WidgetsKit.getWidgetData(dataId, defaultValue: defaultValue);
    final arguments = await passedArguments.future;

    expect(arguments['defaultValue'], defaultValue);
  });

  test('getWidgetData passes appGroupId when provided', () async {
    const dataId = 'TestId';
    const appGroupId = 'group.test.per.call';
    await WidgetsKit.getWidgetData<String>(dataId, appGroupId: appGroupId);
    final arguments = await passedArguments.future;

    expect(arguments['id'], dataId);
    expect(arguments['appGroupId'], appGroupId);
  });

  group('saveWidgetData', () {
    test('saves data with value', () async {
      const id = 'TestId';
      const value = 'Test Value';
      expect(await WidgetsKit.saveWidgetData(id, value), true);
      final arguments = await passedArguments.future;

      expect(arguments['id'], id);
      expect(arguments['data'], value);
    });

    test('passes appGroupId when provided', () async {
      const id = 'TestId';
      const value = 'Test Value';
      const appGroupId = 'group.test.per.call';
      expect(
        await WidgetsKit.saveWidgetData(id, value, appGroupId: appGroupId),
        true,
      );
      final arguments = await passedArguments.future;

      expect(arguments['id'], id);
      expect(arguments['data'], value);
      expect(arguments['appGroupId'], appGroupId);
    });

    group('deleteFile', () {
      late List<MethodCall> invocations;
      dynamic getWidgetDataReturn;
      Object? getWidgetDataError;

      setUp(() {
        invocations = [];
        getWidgetDataReturn = null;
        getWidgetDataError = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        // ignore: body_might_complete_normally_nullable
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          invocations.add(call);
          switch (call.method) {
            case 'getWidgetData':
              if (getWidgetDataError != null) throw getWidgetDataError!;
              return getWidgetDataReturn;
            case 'saveWidgetData':
              return true;
            default:
              return null;
          }
        });
      });

      test('deleteFile false with null only invokes saveWidgetData', () async {
        const id = 'TestId';
        expect(
          await WidgetsKit.saveWidgetData(id, null, deleteFile: false),
          true,
        );
        expect(invocations.length, 1);
        expect(invocations.single.method, 'saveWidgetData');
        expect(invocations.single.arguments['id'], id);
        expect(invocations.single.arguments['data'], isNull);
      });

      test(
        'non-String path skips delete; getWidgetData then saveWidgetData',
        () async {
          getWidgetDataReturn = 42;
          const id = 'fileKey';
          expect(await WidgetsKit.saveWidgetData(id, null), true);
          expect(invocations.map((c) => c.method).toList(), [
            'getWidgetData',
            'saveWidgetData',
          ]);
          expect(invocations[0].arguments['id'], id);
          expect(invocations[1].arguments['data'], isNull);
        },
      );

      test('delete flow forwards appGroupId to get and save', () async {
        getWidgetDataReturn = '/widget/file.bin';
        const id = 'fileKey';
        const appGroupId = 'group.test.per.call';
        expect(
          await WidgetsKit.saveWidgetData(id, null, appGroupId: appGroupId),
          true,
        );
        expect(invocations.map((c) => c.method).toList(), [
          'getWidgetData',
          'saveWidgetData',
        ]);
        expect(invocations[0].arguments['id'], id);
        expect(invocations[0].arguments['appGroupId'], appGroupId);
        expect(invocations[1].arguments['id'], id);
        expect(invocations[1].arguments['data'], isNull);
        expect(invocations[1].arguments['appGroupId'], appGroupId);
      });

      test('String path not under widgets_kit skips file delete', () async {
        getWidgetDataReturn = '/widget/file.bin';
        final file = MockFile();

        await IOOverrides.runZoned(
          () async {
            expect(await WidgetsKit.saveWidgetData('k', null), true);
            verifyNever(() => file.exists());
            verifyNever(() => file.delete());
          },
          createFile: (path) {
            when(() => file.path).thenReturn(path);
            return file;
          },
        );

        expect(invocations.map((c) => c.method), [
          'getWidgetData',
          'saveWidgetData',
        ]);
      });

      test('managed path missing file never calls delete', () async {
        getWidgetDataReturn = '/app/support/widgets_kit/missing.bin';
        final file = MockFile();
        when(() => file.exists()).thenAnswer((_) async => false);

        await IOOverrides.runZoned(
          () async {
            expect(await WidgetsKit.saveWidgetData('k', null), true);
            verify(() => file.exists()).called(1);
            verifyNever(() => file.delete());
          },
          createFile: (path) {
            when(() => file.path).thenReturn(path);
            return file;
          },
        );
      });

      test('managed path existing file deletes once', () async {
        getWidgetDataReturn = '/app/support/widgets_kit/file.bin';
        final file = MockFile();
        when(() => file.exists()).thenAnswer((_) async => true);
        when(() => file.delete()).thenAnswer((_) async => file);

        await IOOverrides.runZoned(
          () async {
            expect(await WidgetsKit.saveWidgetData('k', null), true);
            verify(() => file.delete()).called(1);
          },
          createFile: (path) {
            when(() => file.path).thenReturn(path);
            return file;
          },
        );
      });

      test('getWidgetData throws; error propagates so caller can handle; '
          'saveWidgetData channel not invoked', () async {
        getWidgetDataError = Exception('channel fail');
        await expectLater(
          WidgetsKit.saveWidgetData('id', null),
          throwsA(anything),
        );
        expect(invocations.map((c) => c.method), ['getWidgetData']);
        expect(invocations.any((c) => c.method == 'saveWidgetData'), isFalse);
      });

      test(
        'exists throws; error propagates; saveWidgetData channel not invoked',
        () async {
          getWidgetDataReturn = '/app/widgets_kit/f';
          final file = MockFile();
          when(() => file.exists()).thenThrow(Exception('io'));

          await IOOverrides.runZoned(
            () async {
              await expectLater(
                WidgetsKit.saveWidgetData('id', null),
                throwsA(anything),
              );
            },
            createFile: (path) {
              when(() => file.path).thenReturn(path);
              return file;
            },
          );

          expect(invocations.map((c) => c.method), ['getWidgetData']);
          expect(invocations.any((c) => c.method == 'saveWidgetData'), isFalse);
        },
      );

      test(
        'managed path delete failure is ignored; saveWidgetData still invoked',
        () async {
          getWidgetDataReturn = '/app/widgets_kit/f';
          final file = MockFile();
          when(() => file.exists()).thenAnswer((_) async => true);
          when(() => file.delete()).thenAnswer(
            (_) async => throw FileSystemException('delete', 'path'),
          );

          await IOOverrides.runZoned(
            () async {
              expect(await WidgetsKit.saveWidgetData('id', null), true);
            },
            createFile: (path) {
              when(() => file.path).thenReturn(path);
              return file;
            },
          );

          expect(invocations.map((c) => c.method), [
            'getWidgetData',
            'saveWidgetData',
          ]);
        },
      );
    });
  });

  test('updateWidget', () async {
    expect(
      await WidgetsKit.updateWidget(
        name: 'name',
        androidName: 'androidName',
        iOSName: 'iOSName',
        qualifiedAndroidName: 'com.example.androidName',
      ),
      true,
    );

    final arguments = await passedArguments.future;

    expect(arguments['name'], 'name');
    expect(arguments['android'], 'androidName');
    expect(arguments['ios'], 'iOSName');
    expect(arguments['qualifiedAndroidName'], 'com.example.androidName');
  });

  test('updateWidgetPreview', () async {
    expect(
      await WidgetsKit.updateWidgetPreview(
        name: 'name',
        androidName: 'androidName',
        qualifiedAndroidName: 'com.example.androidName',
      ),
      true,
    );

    final arguments = await passedArguments.future;

    expect(arguments['name'], 'name');
    expect(arguments['android'], 'androidName');
    expect(arguments.containsKey('ios'), false);
    expect(arguments['qualifiedAndroidName'], 'com.example.androidName');
  });

  group('scheduleWidgetUpdates', () {
    test('passes epoch milliseconds in the given order and names', () async {
      final later = DateTime.utc(2024, 1, 2, 3, 4, 5);
      final earlier = DateTime.utc(2023, 12, 31, 23, 59, 59);

      expect(
        await WidgetsKit.scheduleWidgetUpdates(
          [later, earlier],
          name: 'name',
          androidName: 'androidName',
          qualifiedAndroidName: 'com.example.androidName',
        ),
        true,
      );

      final arguments = await passedArguments.future;

      // The platform side filters, de-duplicates and sorts authoritatively.
      expect(arguments['updateTimes'], [
        later.millisecondsSinceEpoch,
        earlier.millisecondsSinceEpoch,
      ]);
      expect(arguments['name'], 'name');
      expect(arguments['android'], 'androidName');
      expect(arguments['qualifiedAndroidName'], 'com.example.androidName');
    });

    test(
      'local and UTC DateTimes of the same instant are equivalent',
      () async {
        final local = DateTime(2024, 6, 1, 12);
        final utc = local.toUtc();
        expect(local.isAtSameMomentAs(utc), isTrue);

        await WidgetsKit.scheduleWidgetUpdates([local], name: 'name');
        final localArguments = await passedArguments.future;

        passedArguments = Completer();
        await WidgetsKit.scheduleWidgetUpdates([utc], name: 'name');
        final utcArguments = await passedArguments.future;

        expect(localArguments['updateTimes'], utcArguments['updateTimes']);
        expect(localArguments['updateTimes'], [local.millisecondsSinceEpoch]);
      },
    );

    test('passes an empty list', () async {
      await WidgetsKit.scheduleWidgetUpdates([], name: 'name');

      final arguments = await passedArguments.future;

      expect(arguments['updateTimes'], isEmpty);
      expect(arguments['name'], 'name');
      expect(arguments['android'], isNull);
      expect(arguments['qualifiedAndroidName'], isNull);
    });
  });

  test('cancelScheduledWidgetUpdates', () async {
    expect(
      await WidgetsKit.cancelScheduledWidgetUpdates(
        name: 'name',
        androidName: 'androidName',
        qualifiedAndroidName: 'com.example.androidName',
      ),
      true,
    );

    final arguments = await passedArguments.future;

    expect(arguments['name'], 'name');
    expect(arguments['android'], 'androidName');
    expect(arguments['qualifiedAndroidName'], 'com.example.androidName');
  });

  test('canScheduleExactWidgetUpdates', () async {
    expect(await WidgetsKit.canScheduleExactWidgetUpdates(), true);
  });

  test('isRequestPinWidgetSupported', () async {
    expect(await WidgetsKit.isRequestPinWidgetSupported(), true);

    final arguments = await passedArguments.future;

    expect(arguments, isNull);
  });

  test('requestPinWidget', () async {
    await WidgetsKit.requestPinWidget(
      name: 'name',
      androidName: 'androidName',
      qualifiedAndroidName: 'com.example.androidName',
    );

    final arguments = await passedArguments.future;

    expect(arguments['name'], 'name');
    expect(arguments['android'], 'androidName');
    expect(arguments['qualifiedAndroidName'], 'com.example.androidName');
  });

  group('initiallyLaunchedFromWidgetsKit', () {
    test('Valid Uri String gets parsed', () async {
      launchUri = 'widgetsKit://widgetsKitTest';

      final parsedUri = await WidgetsKit.initiallyLaunchedFromWidgetsKit();

      expect(parsedUri, Uri(scheme: 'widgetsKit', host: 'widgetsKitTest'));
    });

    test('Malformed Uri String returns empty Uri', () async {
      launchUri = 'tcp://[fe80::a8e8:2b42:3c07:c04a%2510]:port/name';

      final parsedUri = await WidgetsKit.initiallyLaunchedFromWidgetsKit();

      expect(parsedUri, Uri());
    });

    test('null return value returns null', () async {
      launchUri = null;

      final parsedUri = await WidgetsKit.initiallyLaunchedFromWidgetsKit();

      expect(parsedUri, null);
    });
  });

  group('initiallyLaunchedFromWidgetsKitConfigure', () {
    test('Valid widget ID is returned', () async {
      configureWidgetId = '7';

      final returnedId =
          await WidgetsKit.initiallyLaunchedFromWidgetsKitConfigure();

      expect(returnedId, '7');
    });

    test('null return value returns null', () async {
      configureWidgetId = null;

      final returnedId =
          await WidgetsKit.initiallyLaunchedFromWidgetsKitConfigure();

      expect(returnedId, null);
    });
  });

  test('finishWidgetsKitConfigure', () async {
    await WidgetsKit.finishWidgetsKitConfigure();
    final arguments = await passedArguments.future;

    expect(arguments, isNull);
  });

  test('Set Group Id', () async {
    const appGroup = 'Default Value';
    await WidgetsKit.setAppGroupId(appGroup);
    final arguments = await passedArguments.future;

    expect(arguments['groupId'], appGroup);
  });

  test('per-call appGroupId does not change global groupId', () async {
    const globalGroupId = 'group.global';
    const perCallGroupId = 'group.per.call';
    final invocations = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          invocations.add(call);
          switch (call.method) {
            case 'setAppGroupId':
              return true;
            case 'saveWidgetData':
              return true;
            default:
              return null;
          }
        });

    await WidgetsKit.setAppGroupId(globalGroupId);
    await WidgetsKit.saveWidgetData('k', 'v', appGroupId: perCallGroupId);
    expect(WidgetsKit.groupId, globalGroupId);
    expect(invocations.last.arguments['appGroupId'], perCallGroupId);
  });

  test('Register Background Callback passes Handles', () async {
    final dispatcherHandle = PluginUtilities.getCallbackHandle(
      callbackDispatcher,
    )?.toRawHandle();
    final callbackHandle = PluginUtilities.getCallbackHandle(
      testCallback,
    )?.toRawHandle();

    // ignore: deprecated_member_use_from_same_package
    expect(await WidgetsKit.registerBackgroundCallback(testCallback), true);

    final argument = await passedArguments.future;

    expect(argument[0], dispatcherHandle);
    expect(argument[1], callbackHandle);
  });

  test('Register Interactivity Callback passes Handles', () async {
    final dispatcherHandle = PluginUtilities.getCallbackHandle(
      callbackDispatcher,
    )?.toRawHandle();
    final callbackHandle = PluginUtilities.getCallbackHandle(
      testCallback,
    )?.toRawHandle();

    expect(await WidgetsKit.registerInteractivityCallback(testCallback), true);

    final argument = await passedArguments.future;

    expect(argument[0], dispatcherHandle);
    expect(argument[1], callbackHandle);
  });

  test('Register Interactivity Callback rejects a closure', () async {
    await expectLater(
      WidgetsKit.registerInteractivityCallback((Uri? uri) {}),
      throwsArgumentError,
    );

    expect(
      passedArguments.isCompleted,
      isFalse,
      reason: 'a callback without a handle must not reach the platform',
    );
  });

  group('unsupported platforms', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('isSupported is true only on Android, iOS and macOS', () {
      for (final platform in TargetPlatform.values) {
        debugDefaultTargetPlatformOverride = platform;
        final expected =
            platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS ||
            platform == TargetPlatform.macOS;
        expect(WidgetsKit.isSupported, expected, reason: '$platform');
      }
    });

    test('calls return safe values and never reach the platform', () async {
      expect(await WidgetsKit.saveWidgetData<String>('id', 'x'), false);
      expect(await WidgetsKit.getWidgetData<String>('id'), isNull);
      expect(
        await WidgetsKit.getWidgetData<String>('id', defaultValue: 'fallback'),
        'fallback',
      );
      expect(await WidgetsKit.updateWidget(name: 'Provider'), false);
      expect(await WidgetsKit.updateWidgetPreview(name: 'Provider'), false);
      expect(
        await WidgetsKit.scheduleWidgetUpdates([DateTime(2030)], name: 'P'),
        false,
      );
      expect(await WidgetsKit.cancelScheduledWidgetUpdates(name: 'P'), false);
      expect(await WidgetsKit.canScheduleExactWidgetUpdates(), false);
      expect(await WidgetsKit.isRequestPinWidgetSupported(), false);
      await WidgetsKit.requestPinWidget(name: 'P');
      expect(await WidgetsKit.setAppGroupId('group.example'), false);
      expect(await WidgetsKit.initiallyLaunchedFromWidgetsKit(), isNull);
      expect(
        await WidgetsKit.initiallyLaunchedFromWidgetsKitConfigure(),
        isNull,
      );
      await WidgetsKit.finishWidgetsKitConfigure();
      expect(await WidgetsKit.getInstalledWidgets(), isEmpty);
      expect(await WidgetsKit.widgetClicked.isEmpty, isTrue);
      expect(
        // ignore: deprecated_member_use_from_same_package
        await WidgetsKit.registerBackgroundCallback(testCallback),
        false,
      );
      expect(
        await WidgetsKit.registerInteractivityCallback(testCallback),
        false,
      );

      expect(
        passedArguments.isCompleted,
        isFalse,
        reason: 'nothing may be sent to a platform that has no widgets',
      );
    });

    test('helpers that produce a file say the platform is unsupported', () async {
      await expectLater(
        WidgetsKit.saveFile('key', Uint8List(1)),
        throwsUnsupportedError,
      );
      await expectLater(
        WidgetsKit.renderFlutterWidget(
          const SizedBox(width: 1, height: 1),
          key: 'key',
        ),
        throwsUnsupportedError,
      );
    });
  });

  for (final platform in [TargetPlatform.windows, TargetPlatform.linux]) {
    group('file store on $platform', () {
      late Directory storage;

      setUp(() {
        debugDefaultTargetPlatformOverride = platform;
        storage = Directory.systemTemp.createTempSync('widgets_kit_store');
        WidgetsKit.debugStorageDirectory = storage;
      });

      tearDown(() {
        debugDefaultTargetPlatformOverride = null;
        WidgetsKit.debugStorageDirectory = null;
        storage.deleteSync(recursive: true);
      });

      test('has no home screen widgets but keeps a data store', () {
        expect(WidgetsKit.isSupported, isFalse);
      });

      test('saved data is read back with its type', () async {
        expect(await WidgetsKit.saveWidgetData<String>('title', 'Hi'), true);
        expect(await WidgetsKit.saveWidgetData<int>('count', 7), true);
        expect(await WidgetsKit.saveWidgetData<double>('price', 12.5), true);
        expect(await WidgetsKit.saveWidgetData<bool>('on', true), true);

        expect(await WidgetsKit.getWidgetData<String>('title'), 'Hi');
        expect(await WidgetsKit.getWidgetData<int>('count'), 7);
        expect(await WidgetsKit.getWidgetData<double>('price'), 12.5);
        expect(await WidgetsKit.getWidgetData<bool>('on'), true);
      });

      test('data survives a restart because it is written to disk', () async {
        await WidgetsKit.saveWidgetData<String>('title', 'persisted');

        final file = File('${storage.path}/widget_data.json');
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), contains('persisted'));
      });

      test('saving null removes the value', () async {
        await WidgetsKit.saveWidgetData<String>('gone', 'x');

        await WidgetsKit.saveWidgetData<String>('gone', null);

        expect(
          await WidgetsKit.getWidgetData<String>('gone', defaultValue: 'd'),
          'd',
        );
      });

      test('concurrent saves keep every value', () async {
        await Future.wait([
          for (var i = 0; i < 20; i++)
            WidgetsKit.saveWidgetData<int>('key$i', i),
        ]);

        for (var i = 0; i < 20; i++) {
          expect(await WidgetsKit.getWidgetData<int>('key$i'), i);
        }
      });

      test('calls that need a widget system still answer false', () async {
        expect(await WidgetsKit.updateWidget(name: 'P'), false);
        expect(await WidgetsKit.getInstalledWidgets(), isEmpty);
      });

      test('saveFile writes the file and stores its path', () async {
        final path = await WidgetsKit.saveFile('logo', Uint8List.fromList([1, 2, 3]));

        expect(File(path).readAsBytesSync(), [1, 2, 3]);
        expect(await WidgetsKit.getWidgetData<String>('logo'), path);
      });
    });
  }

  group('Widget Clicked', () {
    test('Send Uris to Stream', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            updateChannel.name,
            // ignore: body_might_complete_normally_nullable
            (message) async {
              emitEvent(
                updateChannel.codec.encodeSuccessEnvelope(
                  'widgetsKit://widgetsKitTest',
                ),
              );
              emitEvent(updateChannel.codec.encodeSuccessEnvelope(2));
              emitEvent(updateChannel.codec.encodeSuccessEnvelope(null));
            },
          );

      final expectation = expectLater(
        WidgetsKit.widgetClicked,
        emitsInOrder([Uri.parse('widgetsKit://widgetsKitTest'), Uri(), null]),
      );

      await expectation;
    });
  });

  group('Render Flutter Widget', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final directory = Directory('app/directory');

    const size = Size(201, 201);
    final targetWidget = SizedBox.fromSize(
      size: size,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: ColoredBox(color: Colors.red)),
          Expanded(child: ColoredBox(color: Colors.green)),
          Expanded(child: ColoredBox(color: Colors.blue)),
        ],
      ),
    );

    setUp(() {
      final pathProvider = MockPathProvider();
      when(
        () => pathProvider.getApplicationSupportPath(),
      ).thenAnswer((invocation) async => directory.path);
      PathProviderPlatform.instance = pathProvider;
    });

    testGoldens('Render Flutter Widget', (tester) async {
      final byteCompleter = Completer<Uint8List>();
      final file = MockFile();

      when(() => file.exists()).thenAnswer((invocation) async => false);
      when(
        () => file.create(recursive: true),
      ).thenAnswer((invocation) async => file);
      when(() => file.writeAsBytes(any())).thenAnswer((invocation) async {
        byteCompleter.complete(
          Uint8List.fromList(invocation.positionalArguments.first as List<int>),
        );
        return file;
      });

      await IOOverrides.runZoned(
        () async {
          await tester.runAsync(() async {
            final path = await WidgetsKit.renderFlutterWidget(
              targetWidget,
              key: 'screenshot',
              logicalSize: size,
            );
            final expectedPath = '${directory.path}/widgets_kit/screenshot.png';
            expect(path, equals(expectedPath));

            final arguments = await passedArguments.future;
            expect(arguments['id'], 'screenshot');
            expect(arguments['data'], expectedPath);
          });
        },
        createFile: (path) {
          when(() => file.path).thenReturn(path);
          return file;
        },
      );

      final bytes = await byteCompleter.future;

      await tester.pumpWidgetBuilder(
        Image.memory(bytes, width: size.height, height: size.height),
        surfaceSize: size,
      );

      await tester.pumpAndSettle();
      await screenMatchesGolden(tester, 'render-flutter-widget');
    });

    testGoldens('Error rendering Flutter Widget throws', (tester) async {
      final file = MockFile();
      await IOOverrides.runZoned(
        () async {
          await tester.runAsync(() async {
            expect(
              () async => await WidgetsKit.renderFlutterWidget(
                Builder(builder: (_) => const SizedBox()),
                logicalSize: Size.zero,
                key: 'screenshot',
              ),
              throwsException,
            );
          });
        },
        createFile: (path) {
          when(() => file.path).thenReturn(path);
          return file;
        },
      );
    });

    testGoldens('Error saving Widget throws', (tester) async {
      final file = MockFile();

      when(() => file.exists()).thenAnswer((invocation) async => false);
      when(
        () => file.create(recursive: true),
      ).thenAnswer((invocation) async => file);
      when(
        () => file.writeAsBytes(any()),
      ).thenAnswer((invocation) => Future.error('Error'));

      await IOOverrides.runZoned(
        () async {
          await tester.runAsync(() async {
            expect(
              () async => await WidgetsKit.renderFlutterWidget(
                targetWidget,
                logicalSize: size,
                key: 'screenshot',
              ),
              throwsException,
            );
          });
        },
        createFile: (path) {
          when(() => file.path).thenReturn(path);
          return file;
        },
      );
    });
  });

  group('saveFile', () {
    final directory = Directory('app/directory');

    setUp(() {
      final pathProvider = MockPathProvider();
      when(
        () => pathProvider.getApplicationSupportPath(),
      ).thenAnswer((invocation) async => directory.path);
      PathProviderPlatform.instance = pathProvider;
    });

    test('writes bytes and saves path to widget data', () async {
      final file = MockFile();
      final payload = Uint8List.fromList([1, 2, 3]);

      when(() => file.exists()).thenAnswer((invocation) async => false);
      when(
        () => file.create(recursive: true),
      ).thenAnswer((invocation) async => file);
      when(() => file.writeAsBytes(any())).thenAnswer((invocation) async {
        expect(invocation.positionalArguments.first, orderedEquals(payload));
        return file;
      });

      await IOOverrides.runZoned(
        () async {
          final path = await WidgetsKit.saveFile(
            'myKey',
            payload,
            extension: 'json',
          );
          expect(path, '${directory.path}/widgets_kit/myKey.json');
          final arguments = await passedArguments.future;
          expect(arguments['id'], 'myKey');
          expect(arguments['data'], path);
        },
        createFile: (path) {
          when(() => file.path).thenReturn(path);
          return file;
        },
      );
    });

    test('passes appGroupId to saved widget path metadata', () async {
      final file = MockFile();
      final payload = Uint8List.fromList([1, 2, 3]);

      when(() => file.exists()).thenAnswer((invocation) async => false);
      when(
        () => file.create(recursive: true),
      ).thenAnswer((invocation) async => file);
      when(
        () => file.writeAsBytes(any()),
      ).thenAnswer((invocation) async => file);

      await IOOverrides.runZoned(
        () async {
          final path = await WidgetsKit.saveFile(
            'myKey',
            payload,
            extension: 'json',
            appGroupId: 'group.test.per.call',
          );
          expect(path, '${directory.path}/widgets_kit/myKey.json');
          final arguments = await passedArguments.future;
          expect(arguments['id'], 'myKey');
          expect(arguments['data'], path);
          expect(arguments['appGroupId'], 'group.test.per.call');
        },
        createFile: (path) {
          when(() => file.path).thenReturn(path);
          return file;
        },
      );
    });

    test('strips leading dot from extension', () async {
      final file = MockFile();
      final payload = Uint8List.fromList([1, 2, 3]);

      when(() => file.exists()).thenAnswer((invocation) async => false);
      when(
        () => file.create(recursive: true),
      ).thenAnswer((invocation) async => file);
      when(() => file.writeAsBytes(any())).thenAnswer((invocation) async {
        return file;
      });

      await IOOverrides.runZoned(
        () async {
          final path = await WidgetsKit.saveFile(
            'myKey',
            payload,
            extension: '.json',
          );
          expect(path, '${directory.path}/widgets_kit/myKey.json');
        },
        createFile: (path) {
          when(() => file.path).thenReturn(path);
          return file;
        },
      );
    });

    test('rejects invalid key', () async {
      expect(() => WidgetsKit.saveFile('', Uint8List(0)), throwsArgumentError);
      expect(
        () => WidgetsKit.saveFile('../x', Uint8List(0)),
        throwsArgumentError,
      );
      expect(
        () => WidgetsKit.saveFile('a b', Uint8List(0)),
        throwsArgumentError,
      );
    });

    test('rejects invalid extension', () async {
      expect(
        () => WidgetsKit.saveFile('k', Uint8List(0), extension: ''),
        throwsArgumentError,
      );
      expect(
        () => WidgetsKit.saveFile('k', Uint8List(0), extension: 'a/b'),
        throwsArgumentError,
      );
    });
  });

  group('saveImage', () {
    final directory = Directory('app/directory');

    setUp(() {
      final pathProvider = MockPathProvider();
      when(
        () => pathProvider.getApplicationSupportPath(),
      ).thenAnswer((invocation) async => directory.path);
      PathProviderPlatform.instance = pathProvider;
    });

    testWidgets('encodes ImageProvider to PNG and saves via saveFile', (
      tester,
    ) async {
      final file = MockFile();

      when(() => file.exists()).thenAnswer((invocation) async => false);
      when(
        () => file.create(recursive: true),
      ).thenAnswer((invocation) async => file);
      when(() => file.writeAsBytes(any())).thenAnswer((invocation) async {
        expect(
          (invocation.positionalArguments.first as List<int>).length,
          greaterThan(0),
        );
        return file;
      });

      await IOOverrides.runZoned(
        () async {
          await tester.runAsync(() async {
            final path = await WidgetsKit.saveImage(
              'shot',
              MemoryImage(kTestPngBytes),
            );
            expect(path, '${directory.path}/widgets_kit/shot.png');
            final arguments = await passedArguments.future;
            expect(arguments['id'], 'shot');
            expect(arguments['data'], path);
          });
        },
        createFile: (path) {
          when(() => file.path).thenReturn(path);
          return file;
        },
      );
    });

    testWidgets('propagates error when image bytes cannot be decoded', (
      tester,
    ) async {
      await IOOverrides.runZoned(() async {
        await tester.runAsync(() async {
          await expectLater(
            WidgetsKit.saveImage(
              'bad',
              MemoryImage(Uint8List.fromList(<int>[0, 1, 2, 3, 4])),
            ),
            throwsA(anything),
          );
        });
      }, createFile: (path) => MockFile());
    });
  });

  group('getInstalledWidgets', () {
    test(
      'returns a list of WidgetsKitInfo objects when method channel provides data',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              switch (methodCall.method) {
                case 'getInstalledWidgets':
                  return [
                    {"id": "widget1", "name": "Widget One"},
                    {"id": "widget2", "name": "Widget Two"},
                  ];
                default:
                  return null;
              }
            });

        final expectedWidgets = [
          WidgetsKitInfo.fromMap({"id": "widget1", "name": "Widget One"}),
          WidgetsKitInfo.fromMap({"id": "widget2", "name": "Widget Two"}),
        ];

        final widgets = await WidgetsKit.getInstalledWidgets();

        expect(widgets, equals(expectedWidgets));
      },
    );

    test('returns an empty list when method channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      // ignore: body_might_complete_normally_nullable
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getInstalledWidgets':
            return null;
        }
      });

      final widgets = await WidgetsKit.getInstalledWidgets();

      expect(widgets, isEmpty);
    });
  });
}

void emitEvent(ByteData? event) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(updateChannel.name, event, (ByteData? reply) {});
}

Future<void> testCallback(Uri? uri) async {
  debugPrint('Called TestCallback');
}
