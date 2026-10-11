package com.widgetskit.widgets_kit

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.util.Log
import androidx.core.app.JobIntentService
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean

@Deprecated(
    message =
        "This class uses the deprecated JobIntentService. Use WidgetsKitBackgroundWorker instead. If encountered in the Android Manifest you can remove this service entry",
    replaceWith =
        ReplaceWith(
            "WidgetsKitBackgroundWorker",
            "com.widgetskit.widgets_kit.WidgetsKitBackgroundWorker",
        ),
    level = DeprecationLevel.WARNING,
)
class WidgetsKitBackgroundService : MethodChannel.MethodCallHandler, JobIntentService() {

  private val queue = ArrayDeque<List<Any>>()
  private lateinit var channel: MethodChannel
  private lateinit var context: Context

  companion object {
    private const val TAG = "WidgetsKitService"
    private val JOB_ID = UUID.randomUUID().mostSignificantBits.toInt()
    private var engine: FlutterEngine? = null

    private val serviceStarted = AtomicBoolean(false)

    fun enqueueWork(context: Context, work: Intent) {
      enqueueWork(context, WidgetsKitBackgroundService::class.java, JOB_ID, work)
    }
  }

  override fun onCreate() {
    super.onCreate()
    synchronized(serviceStarted) {
      context = this
      if (engine == null) {
        val callbackHandle = WidgetsKitPlugin.getDispatcherHandle(context)

        if (callbackHandle == 0L) {
          Log.e(TAG, "No callbackHandle saved. Did you call WidgetsKit.registerBackgroundCallback?")
        }

        engine = FlutterEngine(context)

        val callbackInfo =
            FlutterCallbackInformation.lookupCallbackInformation(callbackHandle) ?: return

        val callback =
            DartExecutor.DartCallback(
                context.assets,
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                callbackInfo,
            )
        engine?.dartExecutor?.executeDartCallback(callback)
      }
    }
    channel =
        MethodChannel(engine!!.getDartExecutor().getBinaryMessenger(), "widgets_kit/background")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    if (call.method == "WidgetsKit.backgroundInitialized") {
      synchronized(serviceStarted) {
        while (!queue.isEmpty()) {
          channel.invokeMethod("", queue.remove())
        }
        serviceStarted.set(true)
      }
    }
  }

  override fun onHandleWork(intent: Intent) {
    val data = intent.data?.toString() ?: ""
    val args = listOf(WidgetsKitPlugin.getHandle(context), data)

    synchronized(serviceStarted) {
      if (!serviceStarted.get()) {
        queue.add(args)
      } else {
        Handler(context.mainLooper).post { channel.invokeMethod("", args) }
      }
    }
  }
}
