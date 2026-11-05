package com.reminder.app.reminder_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class ReminderAppWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.reminder_app_widget).apply {
                val pendingCount = widgetData.getInt("today_pending_count", 0)
                setTextViewText(R.id.widget_count_text, "今日 $pendingCount 件")

                val tasksJson = widgetData.getString("today_tasks_json", null)
                if (tasksJson != null && tasksJson.isNotEmpty()) {
                    try {
                        val jsonArray = JSONArray(tasksJson)
                        if (jsonArray.length() > 0) {
                            val item1 = jsonArray.getJSONObject(0)
                            setTextViewText(R.id.widget_task_1, "• ${item1.getString("time")} ${item1.getString("title")}")
                            setViewVisibility(R.id.widget_task_1, View.VISIBLE)

                            if (jsonArray.length() > 1) {
                                val item2 = jsonArray.getJSONObject(1)
                                setTextViewText(R.id.widget_task_2, "• ${item2.getString("time")} ${item2.getString("title")}")
                                setViewVisibility(R.id.widget_task_2, View.VISIBLE)
                            } else {
                                setViewVisibility(R.id.widget_task_2, View.GONE)
                            }

                            if (jsonArray.length() > 2) {
                                val item3 = jsonArray.getJSONObject(2)
                                setTextViewText(R.id.widget_task_3, "• ${item3.getString("time")} ${item3.getString("title")}")
                                setViewVisibility(R.id.widget_task_3, View.VISIBLE)
                            } else {
                                setViewVisibility(R.id.widget_task_3, View.GONE)
                            }
                        } else {
                            setTextViewText(R.id.widget_task_1, "• 今日无待办事项，轻松一刻！")
                            setViewVisibility(R.id.widget_task_2, View.GONE)
                            setViewVisibility(R.id.widget_task_3, View.GONE)
                        }
                    } catch (e: Exception) {
                        setTextViewText(R.id.widget_task_1, "• 今日无待办事项")
                    }
                } else {
                    setTextViewText(R.id.widget_task_1, "• 今日无待办事项")
                    setViewVisibility(R.id.widget_task_2, View.GONE)
                    setViewVisibility(R.id.widget_task_3, View.GONE)
                }

                // 点击桌面小组件直接启动 App
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
