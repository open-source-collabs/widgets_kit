package com.widgetskit.widgets_kit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.FlutterInjector

class WidgetsKitBackgroundReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val flutterLoader = FlutterInjector.instance().flutterLoader()
    flutterLoader.startInitialization(context)
    flutterLoader.ensureInitializationComplete(context, null)
    WidgetsKitBackgroundWorker.enqueueWork(context, intent)
  }
}
