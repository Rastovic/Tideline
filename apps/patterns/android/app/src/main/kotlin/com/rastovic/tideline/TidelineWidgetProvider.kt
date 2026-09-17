package com.rastovic.tideline

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Quick log from the home screen: up to four marker names, each opening the
 * app straight onto that marker's log sheet.
 *
 * Names only. No tick, no count, no value and no colour that follows an entry,
 * because a widget sits on a screen anyone can see, and a mood or a cycle on a
 * home screen is a privacy bug.
 */
class TidelineWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val slots = listOf(R.id.slot_0, R.id.slot_1, R.id.slot_2, R.id.slot_3)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.tideline_widget)

            views.setOnClickPendingIntent(
                R.id.widget_title,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            var shown = 0
            slots.forEachIndexed { index, slot ->
                val id = widgetData.getString("marker_${index}_id", null)
                val name = widgetData.getString("marker_${index}_name", null)
                if (id.isNullOrEmpty() || name.isNullOrEmpty()) {
                    views.setViewVisibility(slot, View.GONE)
                } else {
                    shown++
                    views.setViewVisibility(slot, View.VISIBLE)
                    views.setTextViewText(slot, name)
                    views.setOnClickPendingIntent(
                        slot,
                        HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                            Uri.parse("tideline://log/$id"),
                        ),
                    )
                }
            }
            views.setViewVisibility(
                R.id.widget_empty,
                if (shown == 0) View.VISIBLE else View.GONE,
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
