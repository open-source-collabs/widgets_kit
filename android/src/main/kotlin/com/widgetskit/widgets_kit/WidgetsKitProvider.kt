package com.widgetskit.widgets_kit

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences

abstract class WidgetsKitProvider : AppWidgetProvider() {

  /**
   * Re-arms the scheduled updates of this Widget when its first instance is added.
   *
   * Safety net for an alarm that was lost while no instance existed. The system already draws the
   * current state of the Widget that is being added, so no catch-up update is needed.
   */
  override fun onEnabled(context: Context) {
    super.onEnabled(context)
    WidgetsKitScheduler.pruneAndArmNext(context, javaClass.name, catchUp = false)
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
  ) {
    super.onUpdate(context, appWidgetManager, appWidgetIds)
    onUpdate(context, appWidgetManager, appWidgetIds, WidgetsKitPlugin.getData(context))
  }

  abstract fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  )
}
