package com.alessandro.media_cleaner

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class MediaCleanerWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // home_widget stores data in "home_widget_preferences" SharedPreferences
            val prefs        = context.getSharedPreferences("home_widget_preferences", Context.MODE_PRIVATE)
            val pendingCount = prefs.getInt("pending_count", 0)

            val views = RemoteViews(context.packageName, R.layout.media_cleaner_widget)
            views.setTextViewText(R.id.widget_count, pendingCount.toString())
            views.setTextViewText(
                R.id.widget_label,
                if (pendingCount == 1) "foto da revisionare" else "foto da revisionare"
            )

            // Tap to open the app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = android.app.PendingIntent.getActivity(
                    context, 0, launchIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                            android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
