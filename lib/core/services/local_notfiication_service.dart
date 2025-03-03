import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/notficiation_model.dart';

class LocalNotificationService {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static StreamController<NotificationResponse> streamController =
      StreamController();
  static onTap(NotificationResponse notificationResponse) {
    streamController.add(notificationResponse);
  }

  //! ---------------- 1 setup local notification ----------------------------
  static Future<void> init() async {
    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onTap,
    );
    await requestPermission();
  }

  //! ---------------- 2 show basic local notification ------------------------
  static Future<void> showBasicNotification({
    required NotificationModel notificationModel,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      "id_1",
      "Basic notification",
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOS = DarwinNotificationDetails();

    const NotificationDetails details =
        NotificationDetails(android: androidNotificationDetails, iOS: iOS);
    //-----------------------------------------------------------------
    await flutterLocalNotificationsPlugin.show(
      notificationModel.id,
      notificationModel.title,
      notificationModel.body,
      details,
      payload: notificationModel.payload,
    );
  }

  //! ---------------- 3 repeated local notification --------------------------
  static Future<void> showRepeatedNotification({
    required NotificationModel notificationModel,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      "id_2",
      "Repearted notification",
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOS = DarwinNotificationDetails();

    const RepeatInterval repeatInterval = RepeatInterval.everyMinute;
    const NotificationDetails details =
        NotificationDetails(android: androidNotificationDetails, iOS: iOS);
    //-----------------------------------------------------------------
    await flutterLocalNotificationsPlugin.periodicallyShow(
      notificationModel.id,
      notificationModel.title,
      notificationModel.body,
      repeatInterval,
      details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: notificationModel.payload,
    );
  }

  //!------------------- 4 Schedule local notification -----------------------
  static Future<void> showScheduledNotification({
    required NotificationModel notificationModel,
    required DateTime datetime,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      "id_3",
      "Secheduled notification",
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iOS = DarwinNotificationDetails();

    const NotificationDetails details =
        NotificationDetails(android: androidNotificationDetails, iOS: iOS);

    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
    flutterLocalNotificationsPlugin.zonedSchedule(
      notificationModel.id,
      notificationModel.title,
      notificationModel.body,
      tz.TZDateTime(
        tz.local,
        datetime.year,
        datetime.month,
        datetime.day,
        datetime.hour,
        datetime.minute,
        datetime.second + 10,
      ),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: notificationModel.payload,
    );
  }

  //!----------------- 5 cancel local notification ---------------------------
  static Future<void> cancelNotification({required int id}) async {
    flutterLocalNotificationsPlugin.cancel(id);
  }

  //!----------------- 6 cancel all local notification ------------------------
  static Future<void> cancelAllNotification() async {
    flutterLocalNotificationsPlugin.cancelAll();
  }

  //!----------------- 7 request permission -----------------------------------
  static Future<void> requestPermission() async {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
}
