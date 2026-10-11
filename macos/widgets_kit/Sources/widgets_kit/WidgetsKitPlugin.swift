import Cocoa
import FlutterMacOS
import WidgetKit

/// Connects a Flutter app to WidgetKit widgets on macOS.
///
/// The app and its widget extension share data through an app group. The widget itself is
/// written natively; this plugin saves data for it and asks WidgetKit to reload it.
public class WidgetsKitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  FlutterAppLifecycleDelegate
{
  private static var groupId: String?

  private var initialUrl: URL?
  private var eventSink: FlutterEventSink?

  private let notInitializedError = FlutterError(
    code: "-7", message: "AppGroupId not set. Call setAppGroupId first", details: nil)

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = WidgetsKitPlugin()

    let channel = FlutterMethodChannel(
      name: "widgets_kit", binaryMessenger: registrar.messenger)
    registrar.addMethodCallDelegate(instance, channel: channel)

    let eventChannel = FlutterEventChannel(
      name: "widgets_kit/updates", binaryMessenger: registrar.messenger)
    eventChannel.setStreamHandler(instance)

    registrar.addApplicationDelegate(instance)
  }

  private func resolvedAppGroupId(from call: FlutterMethodCall) -> String? {
    if let args = call.arguments as? [String: Any?],
      let appGroupId = args["appGroupId"] as? String
    {
      return appGroupId
    }
    return WidgetsKitPlugin.groupId
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setAppGroupId":
      if let args = call.arguments as? [String: Any?], let groupId = args["groupId"] as? String {
        WidgetsKitPlugin.groupId = groupId
        result(true)
      } else {
        result(
          FlutterError(
            code: "-6", message: "InvalidArguments setAppGroupId must be called with a group id",
            details: nil))
      }

    case "saveWidgetData":
      guard let resolvedGroupId = resolvedAppGroupId(from: call) else {
        result(notInitializedError)
        return
      }
      guard let args = call.arguments as? [String: Any?],
        let id = args["id"] as? String,
        let data = args["data"]
      else {
        result(
          FlutterError(
            code: "-1", message: "InvalidArguments saveWidgetData must be called with id and data",
            details: nil))
        return
      }
      let preferences = UserDefaults(suiteName: resolvedGroupId)
      // Dart null values in method-channel arguments arrive as NSNull.
      if let value = data, !(value is NSNull) {
        if let binaryData = value as? FlutterStandardTypedData {
          preferences?.setValue(Data(binaryData.data), forKey: id)
        } else {
          preferences?.setValue(value, forKey: id)
        }
      } else {
        preferences?.removeObject(forKey: id)
      }
      result(true)

    case "getWidgetData":
      guard let resolvedGroupId = resolvedAppGroupId(from: call) else {
        result(notInitializedError)
        return
      }
      guard let args = call.arguments as? [String: Any?],
        let id = args["id"] as? String,
        let defaultValue = args["defaultValue"]
      else {
        result(
          FlutterError(
            code: "-2", message: "InvalidArguments getWidgetData must be called with id",
            details: nil))
        return
      }
      let preferences = UserDefaults(suiteName: resolvedGroupId)
      result(preferences?.value(forKey: id) ?? defaultValue)

    case "updateWidget":
      guard let args = call.arguments as? [String: Any?] else {
        result(
          FlutterError(
            code: "-3", message: "InvalidArguments updateWidget must be called with name",
            details: nil))
        return
      }
      // The iOS name wins, then the generic name. Dart null arrives as NSNull.
      let widgetName =
        (args["ios"] as? String) ?? (args["macos"] as? String) ?? (args["name"] as? String)
      guard let name = widgetName else {
        result(
          FlutterError(
            code: "-3", message: "InvalidArguments updateWidget must be called with name",
            details: nil))
        return
      }
      if #available(macOS 11.0, *) {
        WidgetCenter.shared.reloadTimelines(ofKind: name)
        result(true)
      } else {
        result(
          FlutterError(
            code: "-4", message: "Widgets are only available on macOS 11.0 and above",
            details: nil))
      }

    case "getInstalledWidgets":
      if #available(macOS 11.0, *) {
        WidgetCenter.shared.getCurrentConfigurations { configurations in
          switch configurations {
          case .success(let widgets):
            result(
              widgets.map { widget -> [String: Any] in
                ["family": "\(widget.family)", "kind": widget.kind]
              })
          case .failure(let error):
            result(
              FlutterError(
                code: "-8",
                message: "Failed to get installed widgets: \(error.localizedDescription)",
                details: nil))
          }
        }
      } else {
        result(
          FlutterError(
            code: "-4", message: "Widgets are only available on macOS 11.0 and above",
            details: nil))
      }

    case "initiallyLaunchedFromWidgetsKit":
      result(initialUrl?.absoluteString)

    // Preview generation, scheduling, pinning and background callbacks do not exist on macOS.
    // A widget decides for itself when its content changes through its TimelineProvider.
    case "updateWidgetPreview", "scheduleWidgetUpdates", "cancelScheduledWidgetUpdates",
      "canScheduleExactWidgetUpdates", "isRequestPinWidgetSupported",
      "registerBackgroundCallback":
      result(false)

    case "requestPinWidget", "initiallyLaunchedFromWidgetsKitConfigure",
      "finishWidgetsKitConfigure":
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  /// Receives the URL a widget opens the app with.
  public func handleOpen(_ urls: [URL]) -> Bool {
    for url in urls where isWidgetUrl(url: url) {
      if initialUrl == nil {
        initialUrl = url
      }
      eventSink?(url.absoluteString)
      return true
    }
    return false
  }

  private func isWidgetUrl(url: URL) -> Bool {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    return components?.queryItems?.contains(where: { $0.name == "widgetsKit" }) ?? false
  }
}
