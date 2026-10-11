package com.widgetskit.widgets_kit

import android.content.Context
import android.content.SharedPreferences
import android.os.Environment
import androidx.datastore.core.DataStore
import androidx.glance.state.GlanceStateDefinition
import java.io.File
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class WidgetsKitGlanceState(val preferences: SharedPreferences)

class WidgetsKitGlanceStateDefinition : GlanceStateDefinition<WidgetsKitGlanceState> {
  override suspend fun getDataStore(
      context: Context,
      fileKey: String,
  ): DataStore<WidgetsKitGlanceState> {
    val preferences =
        context.getSharedPreferences(WidgetsKitPlugin.PREFERENCES, Context.MODE_PRIVATE)
    return WidgetsKitGlanceDataStore(preferences)
  }

  override fun getLocation(context: Context, fileKey: String): File {
    return Environment.getDataDirectory()
  }
}

private class WidgetsKitGlanceDataStore(private val preferences: SharedPreferences) :
    DataStore<WidgetsKitGlanceState> {
  override val data: Flow<WidgetsKitGlanceState>
    get() = flow { emit(WidgetsKitGlanceState(preferences)) }

  override suspend fun updateData(
      transform: suspend (t: WidgetsKitGlanceState) -> WidgetsKitGlanceState
  ): WidgetsKitGlanceState {
    return transform(WidgetsKitGlanceState(preferences))
  }
}
