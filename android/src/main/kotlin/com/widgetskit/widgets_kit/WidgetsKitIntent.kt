package com.widgetskit.widgets_kit

import android.app.Activity
import android.app.ActivityOptions
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.glance.action.Action
import androidx.glance.appwidget.action.actionStartActivity

object WidgetsKitLaunchIntent {

  const val WIDGETS_KIT_LAUNCH_ACTION = "com.widgetskit.widgets_kit.action.LAUNCH"

  fun <T> getActivity(context: Context, activityClass: Class<T>, uri: Uri? = null): PendingIntent
      where T : Activity {
    val intent = Intent(context, activityClass)
    intent.data = uri
    intent.action = WIDGETS_KIT_LAUNCH_ACTION

    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= 23) {
      flags = flags or PendingIntent.FLAG_IMMUTABLE
    }

    if (Build.VERSION.SDK_INT < 34) {
      return PendingIntent.getActivity(context, 0, intent, flags)
    }

    val options = ActivityOptions.makeBasic()
    if (Build.VERSION.SDK_INT >= 35) {
      options.setPendingIntentCreatorBackgroundActivityStartMode(
          ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
      )
    } else if (Build.VERSION.SDK_INT >= 34) {
      options.pendingIntentBackgroundActivityStartMode =
          ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
    }

    return PendingIntent.getActivity(context, 0, intent, flags, options.toBundle())
  }
}

inline fun <reified T : Activity> actionStartActivity(context: Context, uri: Uri? = null): Action {
  val intent = Intent(context, T::class.java)
  intent.data = uri
  intent.action = WidgetsKitLaunchIntent.WIDGETS_KIT_LAUNCH_ACTION

  return actionStartActivity(intent)
}

object WidgetsKitBackgroundIntent {
  private const val WIDGETS_KIT_BACKGROUND_ACTION = "com.widgetskit.widgets_kit.action.BACKGROUND"

  fun getBroadcast(context: Context, uri: Uri? = null): PendingIntent {
    val intent = Intent(context, WidgetsKitBackgroundReceiver::class.java)
    intent.data = uri
    intent.action = WIDGETS_KIT_BACKGROUND_ACTION

    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= 23) {
      flags = flags or PendingIntent.FLAG_IMMUTABLE
    }

    return PendingIntent.getBroadcast(context, 0, intent, flags)
  }
}
