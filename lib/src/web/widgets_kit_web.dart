import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web registration. Home screen widgets do not exist in a browser, so this registers nothing
/// and every `WidgetsKit` call answers with a safe default. See `WidgetsKit.isSupported`.
class WidgetsKitWeb {
  /// Called by the Flutter tool when the app starts on the web.
  static void registerWith(Registrar registrar) {}
}
