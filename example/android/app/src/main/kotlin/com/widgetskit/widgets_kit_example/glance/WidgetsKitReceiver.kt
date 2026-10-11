package com.widgetskit.widgets_kit_example.glance

import android.content.Context
import androidx.core.os.ConfigurationCompat
import com.widgetskit.widgets_kit.WidgetsKitGlanceWidgetReceiver
import com.widgetskit.widgets_kit.WidgetsKitPlugin

class WidgetsKitReceiver : WidgetsKitGlanceWidgetReceiver<WidgetsKitGlanceAppWidget>() {
  override val glanceAppWidget = WidgetsKitGlanceAppWidget()

  override fun previewFingerprint(context: Context): String {
    val data = WidgetsKitPlugin.getData(context)
    return listOf(
            data.getString("title", ""),
            data.getString("message", ""),
            ConfigurationCompat.getLocales(context.resources.configuration).toLanguageTags(),
        )
        .joinToString("|")
  }
}
