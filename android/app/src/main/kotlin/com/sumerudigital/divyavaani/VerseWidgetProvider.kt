package com.sumerudigital.divyavaani

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Home-screen widget showing the verse of the day. The image is rendered by
/// the Flutter side (HomeWidget.renderFlutterWidget, key "verse_widget").
class VerseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_verse).apply {
                val path = widgetData.getString("verse_widget", null)
                if (path != null) {
                    val bitmap = BitmapFactory.decodeFile(path)
                    if (bitmap != null) setImageViewBitmap(R.id.widget_image, bitmap)
                }
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("divyavaani://verse")
                )
                setOnClickPendingIntent(R.id.widget_image, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
