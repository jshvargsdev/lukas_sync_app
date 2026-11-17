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
        val rates = listOf(
            Triple("widget_usd", R.id.widget_usd, R.id.widget_usd_suffix),
            Triple("widget_eur", R.id.widget_eur, R.id.widget_eur_suffix),
            Triple("widget_usdt", R.id.widget_usdt, R.id.widget_usdt_suffix),
        )
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.rates_widget).apply {
                for ((key, valueId, suffixId) in rates) {
                    val value = widgetData.getString(key, null) ?: empty
                    setTextViewText(valueId, value)
                    // Sin tasa ("—") no se muestra "Bs".
                    setViewVisibility(
                        suffixId,
                        if (value == empty) android.view.View.GONE else android.view.View.VISIBLE,
                    )
                }
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
