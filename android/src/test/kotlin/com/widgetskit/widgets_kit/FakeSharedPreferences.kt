package com.widgetskit.widgets_kit

import android.content.SharedPreferences

/** In-memory [SharedPreferences] that records which thread committed and how often. */
internal class FakeSharedPreferences : SharedPreferences {
  val values = mutableMapOf<String, Any?>()
  var commitCount = 0
  var commitThread: Thread? = null

  override fun getAll(): MutableMap<String, *> = values.toMutableMap()

  override fun getString(key: String?, defValue: String?): String? =
      values[key] as? String ?: defValue

  @Suppress("UNCHECKED_CAST")
  override fun getStringSet(key: String?, defValues: MutableSet<String>?): MutableSet<String>? =
      values[key] as? MutableSet<String> ?: defValues

  override fun getInt(key: String?, defValue: Int): Int = values[key] as? Int ?: defValue

  override fun getLong(key: String?, defValue: Long): Long = values[key] as? Long ?: defValue

  override fun getFloat(key: String?, defValue: Float): Float = values[key] as? Float ?: defValue

  override fun getBoolean(key: String?, defValue: Boolean): Boolean =
      values[key] as? Boolean ?: defValue

  override fun contains(key: String?): Boolean = values.containsKey(key)

  override fun edit(): SharedPreferences.Editor = Editor()

  override fun registerOnSharedPreferenceChangeListener(
      listener: SharedPreferences.OnSharedPreferenceChangeListener?
  ) = Unit

  override fun unregisterOnSharedPreferenceChangeListener(
      listener: SharedPreferences.OnSharedPreferenceChangeListener?
  ) = Unit

  private inner class Editor : SharedPreferences.Editor {
    private val staged = mutableMapOf<String, Any?>()
    private val removed = mutableSetOf<String>()
    private var cleared = false

    override fun putString(key: String, value: String?) = apply { staged[key] = value }

    override fun putStringSet(key: String, values: MutableSet<String>?) = apply {
      staged[key] = values
    }

    override fun putInt(key: String, value: Int) = apply { staged[key] = value }

    override fun putLong(key: String, value: Long) = apply { staged[key] = value }

    override fun putFloat(key: String, value: Float) = apply { staged[key] = value }

    override fun putBoolean(key: String, value: Boolean) = apply { staged[key] = value }

    override fun remove(key: String) = apply { removed += key }

    override fun clear() = apply { cleared = true }

    override fun commit(): Boolean {
      commitCount += 1
      commitThread = Thread.currentThread()
      if (cleared) values.clear()
      removed.forEach { values.remove(it) }
      values.putAll(staged)
      return true
    }

    override fun apply() {
      commit()
    }
  }
}
