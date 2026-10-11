import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:widgets_kit/widgets_kit.dart';
import 'package:workmanager/workmanager.dart';

/// Used for Background Updates using Workmanager Plugin
@pragma("vm:entry-point")
void callbackDispatcher() async {
  Workmanager().executeTask((taskName, inputData) {
    final now = DateTime.now();
    return Future.wait<bool?>([
      WidgetsKit.saveWidgetData('title', 'Updated from Background'),
      WidgetsKit.saveWidgetData(
        'message',
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      ),
    ]).then((value) async {
      Future.wait<bool?>([
        WidgetsKit.updateWidget(
          name: 'WidgetsKitExampleProvider',
          iOSName: 'WidgetsKitExample',
        ),
        if (defaultTargetPlatform == TargetPlatform.android)
          WidgetsKit.updateWidget(
            qualifiedAndroidName:
                'com.widgetskit.widgets_kit_example.glance.WidgetsKitReceiver',
          ),
      ]);
      return !value.contains(false);
    });
  });
}

/// Called when Doing Background Work initiated from Widget
@pragma("vm:entry-point")
Future<void> interactiveCallback(Uri? data) async {
  if (data?.host == 'titleclicked') {
    final greetings = [
      'Hello',
      'Hallo',
      'Bonjour',
      'Hola',
      'Ciao',
      '哈洛',
      '안녕하세요',
      'xin chào',
    ];
    final selectedGreeting = greetings[Random().nextInt(greetings.length)];
    await WidgetsKit.setAppGroupId('YOUR_GROUP_ID');
    await WidgetsKit.saveWidgetData<String>('title', selectedGreeting);
    await WidgetsKit.updateWidget(
      name: 'WidgetsKitExampleProvider',
      iOSName: 'WidgetsKitExample',
    );
    if (defaultTargetPlatform == TargetPlatform.android) {
      await WidgetsKit.updateWidget(
        qualifiedAndroidName:
            'com.widgetskit.widgets_kit_example.glance.WidgetsKitReceiver',
      );
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Background work only exists on Android and iOS. Everywhere else the plugin is a no-op.
  if (WidgetsKit.isSupported) {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
  }
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isRequestPinWidgetSupported = false;

  @override
  void initState() {
    super.initState();
    WidgetsKit.setAppGroupId('YOUR_GROUP_ID');
    WidgetsKit.registerInteractivityCallback(interactiveCallback);
    _checkPinability();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForWidgetLaunch();
    WidgetsKit.widgetClicked.listen(_launchedFromWidget);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future _sendData() async {
    try {
      return await Future.wait([
        WidgetsKit.saveWidgetData<String>('title', _titleController.text),
        WidgetsKit.saveWidgetData<String>('message', _messageController.text),
        // Rendering to a file needs a platform with home screen widgets.
        if (WidgetsKit.isSupported)
          WidgetsKit.renderFlutterWidget(
            const Icon(Icons.flutter_dash, size: 200),
            logicalSize: const Size(200, 200),
            key: 'dashIcon',
          ),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Sending Data. $exception');
    }
  }

  Future _updateWidget() async {
    try {
      return await Future.wait([
        WidgetsKit.updateWidget(
          name: 'WidgetsKitExampleProvider',
          iOSName: 'WidgetsKitExample',
        ),
        if (defaultTargetPlatform == TargetPlatform.android)
          WidgetsKit.updateWidget(
            qualifiedAndroidName:
                'com.widgetskit.widgets_kit_example.glance.WidgetsKitReceiver',
          ),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Updating Widget. $exception');
    }
  }

  Future<void> _updateWidgetPreview() async {
    try {
      final updated = await WidgetsKit.updateWidgetPreview(
        qualifiedAndroidName:
            'com.widgetskit.widgets_kit_example.glance.WidgetsKitReceiver',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Preview updated: $updated')));
    } on PlatformException catch (exception) {
      debugPrint('Error Updating Widget Preview. $exception');
    }
  }

  Future _loadData() async {
    try {
      return await Future.wait([
        WidgetsKit.getWidgetData<String>(
          'title',
          defaultValue: 'Default Title',
        ).then((value) => _titleController.text = value ?? ''),
        WidgetsKit.getWidgetData<String>(
          'message',
          defaultValue: 'Default Message',
        ).then((value) => _messageController.text = value ?? ''),
      ]);
    } on PlatformException catch (exception) {
      debugPrint('Error Getting Data. $exception');
    }
  }

  Future<void> _sendAndUpdate() async {
    await _sendData();
    await _updateWidget();
  }

  void _checkForWidgetLaunch() {
    WidgetsKit.initiallyLaunchedFromWidgetsKit().then(_launchedFromWidget);
  }

  void _launchedFromWidget(Uri? uri) {
    if (uri != null) {
      showDialog(
        context: context,
        builder: (buildContext) => AlertDialog(
          title: const Text('App started from HomeScreenWidget'),
          content: Text('Here is the URI: $uri'),
        ),
      );
    }
  }

  void _startBackgroundUpdate() {
    if (!WidgetsKit.isSupported) return;
    Workmanager().registerPeriodicTask(
      '1',
      'widgetBackgroundUpdate',
      frequency: const Duration(minutes: 15),
    );
  }

  void _stopBackgroundUpdate() {
    if (!WidgetsKit.isSupported) return;
    Workmanager().cancelByUniqueName('1');
  }

  Future<void> _getInstalledWidgets() async {
    try {
      final widgets = await WidgetsKit.getInstalledWidgets();
      if (!mounted) return;

      String getText(WidgetsKitInfo widget) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return 'iOS Family: ${widget.iOSFamily}, iOS Kind: ${widget.iOSKind}';
        } else {
          return 'Android Widget id: ${widget.androidWidgetId}, '
              'Android Class Name: ${widget.androidClassName}, '
              'Android Label: ${widget.androidLabel}';
        }
      }

      await showDialog(
        context: context,
        builder: (buildContext) => AlertDialog(
          title: const Text('Installed Widgets'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Number of widgets: ${widgets.length}'),
              const Divider(),
              for (final widget in widgets) Text(getText(widget)),
            ],
          ),
        ),
      );
    } on PlatformException catch (exception) {
      debugPrint('Error getting widget information. $exception');
    }
  }

  Future<void> _checkPinability() async {
    final isRequestPinWidgetSupported =
        await WidgetsKit.isRequestPinWidgetSupported();
    if (mounted) {
      setState(() {
        _isRequestPinWidgetSupported = isRequestPinWidgetSupported ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WidgetsKit Example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(hintText: 'Title'),
                controller: _titleController,
              ),
              TextField(
                decoration: const InputDecoration(hintText: 'Body'),
                controller: _messageController,
              ),
              ElevatedButton(
                onPressed: _sendAndUpdate,
                child: const Text('Send Data to Widget'),
              ),
              ElevatedButton(
                onPressed: _updateWidgetPreview,
                child: const Text('Update gallery preview'),
              ),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Load Data'),
              ),
              ElevatedButton(
                onPressed: _checkForWidgetLaunch,
                child: const Text('Check For Widget Launch'),
              ),
              if (defaultTargetPlatform == TargetPlatform.android)
                ElevatedButton(
                  onPressed: _startBackgroundUpdate,
                  child: const Text('Update in background'),
                ),
              if (defaultTargetPlatform == TargetPlatform.android)
                ElevatedButton(
                  onPressed: _stopBackgroundUpdate,
                  child: const Text('Stop updating in background'),
                ),
              ElevatedButton(
                onPressed: _getInstalledWidgets,
                child: const Text('Get Installed Widgets'),
              ),
              if (_isRequestPinWidgetSupported)
                ElevatedButton(
                  onPressed: () => WidgetsKit.requestPinWidget(
                    qualifiedAndroidName:
                        'com.widgetskit.widgets_kit_example.glance.WidgetsKitReceiver',
                  ),
                  child: const Text('Pin Widget'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
