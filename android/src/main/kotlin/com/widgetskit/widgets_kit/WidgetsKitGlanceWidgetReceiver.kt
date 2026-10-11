package com.widgetskit.widgets_kit

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.state.updateAppWidgetState
import kotlinx.coroutines.runBlocking

abstract class WidgetsKitGlanceWidgetReceiver<T : GlanceAppWidget> : GlanceAppWidgetReceiver() {

  abstract override val glanceAppWidget: T

  /**
   * Describes what [GlanceAppWidget.providePreview] would currently render for this Widget.
   *
   * [WidgetsKitPreviews.registerAll] compares this against the value stored when the preview was
   * last accepted and only re-registers the preview when it changed, which keeps the system's rate
   * limit for preview updates available for actual changes.
   *
   * Returning `null` (the default) opts the Widget out of the automatic registration.
   */
  open fun previewFingerprint(context: Context): String? = null

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
    runBlocking {
      appWidgetIds.forEach {
        val glanceId = GlanceAppWidgetManager(context).getGlanceIdBy(it)
        glanceAppWidget.apply {
          if (this.stateDefinition is WidgetsKitGlanceStateDefinition) {
            // Must Update State
            updateAppWidgetState<WidgetsKitGlanceState>(
                context = context,
                this.stateDefinition as WidgetsKitGlanceStateDefinition,
                glanceId,
            ) { currentState ->
              currentState
            }
          }
          // Update widget.
          update(context, glanceId)
        }
      }
    }
  }
}
