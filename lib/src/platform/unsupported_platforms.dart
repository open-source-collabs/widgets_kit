/// macOS registration. home screen widgets are not available there, so this does nothing and
/// every `WidgetsKit` call answers with a safe default. See `WidgetsKit.isSupported`.
class WidgetsKitMacOS {
  /// Called by the Flutter tool when the app starts on macOS.
  static void registerWith() {}
}

/// Windows registration. Does nothing. See [WidgetsKitMacOS].
class WidgetsKitWindows {
  /// Called by the Flutter tool when the app starts on Windows.
  static void registerWith() {}
}

/// Linux registration. Does nothing. See [WidgetsKitMacOS].
class WidgetsKitLinux {
  /// Called by the Flutter tool when the app starts on Linux.
  static void registerWith() {}
}
