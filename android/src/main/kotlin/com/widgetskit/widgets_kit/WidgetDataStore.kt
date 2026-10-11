package com.widgetskit.widgets_kit

import android.content.SharedPreferences
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.withContext

/**
 * Reads and writes the key/value data shared with the native widget.
 *
 * Disk access runs on [dispatcher], never on the calling thread, so a slow or contended
 * preferences file cannot block the platform main thread. The default dispatcher runs one task at
 * a time, which keeps writes and the reads that follow them in the order they were requested.
 */
internal class WidgetDataStore(
    private val prefs: SharedPreferences,
    private val dispatcher: CoroutineDispatcher = serialDiskDispatcher,
) {
  sealed interface SaveOutcome {
    /** [persisted] is the result of `commit()`: whether the write reached disk. */
    data class Saved(val persisted: Boolean) : SaveOutcome

    /** The value's type cannot be stored. Nothing was written. */
    data class InvalidType(val typeName: String) : SaveOutcome
  }

  suspend fun save(id: String, data: Any?): SaveOutcome =
      withContext(dispatcher) {
        if (data != null && !isSupported(data)) {
          return@withContext SaveOutcome.InvalidType(data::class.java.simpleName)
        }
        val editor = prefs.edit()
        if (data == null) {
          editor.remove(id)
          editor.remove(doubleMarker(id))
        } else {
          editor.putBoolean(doubleMarker(id), data is Double)
          when (data) {
            is Boolean -> editor.putBoolean(id, data)
            is Float -> editor.putFloat(id, data)
            is String -> editor.putString(id, data)
            is Double -> editor.putLong(id, java.lang.Double.doubleToRawLongBits(data))
            is Int -> editor.putInt(id, data)
            is Long -> editor.putLong(id, data)
          }
        }
        SaveOutcome.Saved(editor.commit())
      }

  suspend fun get(id: String, defaultValue: Any?): Any? =
      withContext(dispatcher) {
        val value = prefs.all[id] ?: return@withContext defaultValue
        if (value is Long && prefs.getBoolean(doubleMarker(id), false)) {
          java.lang.Double.longBitsToDouble(value)
        } else {
          value
        }
      }

  private fun isSupported(data: Any): Boolean =
      data is Boolean ||
          data is Float ||
          data is String ||
          data is Double ||
          data is Int ||
          data is Long

  private fun doubleMarker(id: String) = "$DOUBLE_MARKER_PREFIX$id"

  companion object {
    const val DOUBLE_MARKER_PREFIX = "widgets_kit.double."

    @OptIn(ExperimentalCoroutinesApi::class)
    private val serialDiskDispatcher: CoroutineDispatcher = Dispatchers.IO.limitedParallelism(1)
  }
}
