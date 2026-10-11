package com.widgetskit.widgets_kit_example

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.widgetskit.widgets_kit.WidgetsKitBackgroundIntent
import com.widgetskit.widgets_kit.WidgetsKitLaunchIntent
import com.widgetskit.widgets_kit.WidgetsKitProvider

class WidgetsKitExampleProvider : WidgetsKitProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.example_layout).apply {
            // Open App on Widget Click
            val pendingIntent =
                WidgetsKitLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            // Swap Title Text by calling Dart Code in the Background
            setTextViewText(
                R.id.widget_title,
                widgetData.getString("title", null) ?: "No Title Set",
            )
            val backgroundIntent =
                WidgetsKitBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("widgetsKitExample://titleClicked"),
                )
            setOnClickPendingIntent(R.id.widget_title, backgroundIntent)

            val message = widgetData.getString("message", null)
            setTextViewText(R.id.widget_message, message ?: "No Message Set")
            // Show Images saved with `renderFlutterWidget`
            val image = widgetData.getString("dashIcon", null)
            if (image != null) {
              setImageViewBitmap(R.id.widget_img, BitmapFactory.decodeFile(image))
              setViewVisibility(R.id.widget_img, View.VISIBLE)
            } else {
              setViewVisibility(R.id.widget_img, View.GONE)
            }

            // Detect App opened via Click inside Flutter
            val pendingIntentWithData =
                WidgetsKitLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("widgetsKitExample://message?message=$message"),
                )
            setOnClickPendingIntent(R.id.widget_message, pendingIntentWithData)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
