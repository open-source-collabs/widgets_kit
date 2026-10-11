# widgets_kit

A Flutter plugin that connects your app to native home screen widgets on Android and iOS.

widgets_kit does **not** let you write the widget itself in Flutter. The widget is written with native code (Jetpack Glance or RemoteViews on Android, WidgetKit on iOS). The plugin gives Flutter one interface to push data to those widgets, refresh them, and handle taps.

## Features

- Send data from Flutter to a home screen widget and refresh it
- Render a Flutter widget to an image and show it in a home screen widget
- Interactive widgets that call Dart code
- Schedule widget updates (Android)
- Ask the launcher to pin a widget (Android only, API 26+)
- List the widgets the user has installed

## Platform support

| Platform | Widgets | What the plugin does |
|---|---|---|
| Android | Yes | Full support |
| iOS | Yes | Full support |
| macOS | Yes (WidgetKit, macOS 11+) | Saves data, reloads widgets, lists installed widgets, reports widget taps |
| Windows | Data only | Saves data to a JSON file. Widget refresh is not available |
| Linux | Data only | Saves data to a JSON file. Widget refresh is not available |
| Web | No | Safe no-op |

`WidgetsKit.isSupported` is `true` on Android, iOS and macOS.

### macOS

macOS works like iOS. Add a widget extension to your app, give the app and the extension the same app group, and call `WidgetsKit.setAppGroupId` with it. `saveWidgetData` then writes to the group's shared defaults and `updateWidget(name: ...)` reloads the widget whose `kind` matches. A widget opens the app with a URL that carries a `widgetsKit` query item, and `widgetClicked` delivers it.

macOS has no preview generation, scheduling, pinning or background callbacks. Those calls return `false`.

### Windows and Linux

There is no widget API for the plugin to call on these platforms, so nothing is refreshed. `saveWidgetData` and `getWidgetData` do work: values are kept in `widget_data.json` inside the `widgets_kit` folder of the app support directory, so a native widget provider or another process can read the same data. `saveFile`, `saveImage` and `renderFlutterWidget` write into the same folder. The supported value types are `bool`, `int`, `double` and `String`. Everything that needs a widget system returns `false`, `null` or an empty list.

### Web and other platforms

Calls return a safe default instead of throwing: `false` for the `bool?` methods, `null` for reads (or your `defaultValue`), an empty list for `getInstalledWidgets`, and an empty `widgetClicked` stream. Nothing reaches a platform channel.

Three helpers produce a file and cannot return anything meaningful on the web, so they throw an `UnsupportedError`: `saveFile`, `saveImage` and `renderFlutterWidget`. Check `WidgetsKit.isSupported` (or run on a platform with storage) before calling them:

```dart
if (WidgetsKit.isSupported) {
  await WidgetsKit.renderFlutterWidget(widget, key: 'preview');
}
```

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

## Migrating from home_widget

widgets_kit is not a drop-in replacement. Change these when you switch:

- Imports and calls: `package:home_widget/home_widget.dart` becomes `package:widgets_kit/widgets_kit.dart`, and `HomeWidget.` becomes `WidgetsKit.`.
- Android: the shared preferences file is now `WidgetsKitPreferences` (it was `HomeWidgetPreferences`). Native widget code that reads saved data must open the new name, and data saved under the old name is not carried over.
- Android: classes moved to the package `com.widgetskit.widgets_kit`, so manifest entries that name them need the new package.
- iOS: the plugin, the Swift package product (`widgets-kit`) and the app group handling use the new names.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
