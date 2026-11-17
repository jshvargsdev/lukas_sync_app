package com.joshuavargas.lukassync

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de pantalla de inicio con las tasas oficiales.
 *
 * Los textos llegan ya formateados desde Dart (lib/services/home_widget_sync.dart);
 * las claves deben coincidir con WidgetKeys.
 */
class RatesWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val empty = context.getString(R.string.widget_empty_value)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.rates_widget).apply {
                setTextViewText(R.id.widget_usd, widgetData.getString("widget_usd", empty))
                setTextViewText(R.id.widget_eur, widgetData.getString("widget_eur", empty))
                setTextViewText(R.id.widget_usdt, widgetData.getString("widget_usdt", empty))
                setTextViewText(
                    R.id.widget_updated,
                    widgetData.getString("widget_updated", null)
                        ?: context.getString(R.string.widget_empty_updated),
                )
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
