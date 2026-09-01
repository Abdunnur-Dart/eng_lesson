package com.abdteam.muali

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.abdteam.muali.R

class AppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs: SharedPreferences = context.getSharedPreferences("DATA", Context.MODE_PRIVATE)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.app_widget_layout).apply {
                val letterText = prefs.getString("letter_text", "أ") ?: "أ"
                // NEW: Считывание вариаций написания и процента выполнения урока
                val variationsText = prefs.getString("letter_variations", "") ?: ""
                val progressText = prefs.getString("lesson_progress", "0%") ?: "0%"

                setTextViewText(R.id.widget_content, letterText)
                setTextViewText(R.id.widget_variations, variationsText) // NEW
                setTextViewText(R.id.widget_progress, progressText) // NEW
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}