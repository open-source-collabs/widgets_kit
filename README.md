# widgets_kit

A Flutter plugin that connects your app to native home screen widgets on Android and iOS.

widgets_kit does **not** let you write the widget itself in Flutter. The widget is written with native code (Jetpack Glance or RemoteViews on Android, WidgetKit on iOS). The plugin gives Flutter one interface to push data to those widgets, refresh them, and handle taps.

## Features

- Send data from Flutter to a home screen widget and refresh it
- Render a Flutter widget to an image and show it in a home screen widget
- Interactive widgets that call Dart code
- Schedule widget updates
- Ask the launcher to pin a widget (Android only, API 26+)
- List the widgets the user has installed

## Requirements

- Dart 3.10 or newer
- Flutter 3.38.1 or newer

## Usage

Write the widget on the native side first, then drive it from Dart.

### Save data

```dart
await WidgetsKit.saveWidgetData<String>('id', data);
```

### Update the widget

```dart
await WidgetsKit.updateWidget(
  name: 'WidgetsKitExampleProvider',
);
```

### Read data back

```dart
final String? id = await WidgetsKit.getWidgetData<String>('id');
```

The `example/` app shows complete Android and iOS widgets, background callbacks, and image rendering.

## About this package

widgets_kit is a fork of [home_widget](https://github.com/ABausG/home_widget) 0.10.0 by Anton Borries, used under the BSD 3-Clause licence. The original copyright notice and licence text are kept in [LICENSE](LICENSE), and the original changelog is kept in [CHANGELOG.md](CHANGELOG.md).

What differs from home_widget:

- A different package name, Dart API (`WidgetsKit`), Android package and iOS plugin, so both can be installed in one app.
- Only the core plugin. The CLI and the generator packages are not included.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
