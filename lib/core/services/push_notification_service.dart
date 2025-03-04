import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notficiation_model.dart';
import 'local_notfiication_service.dart';

class PushNotificationService {
  static String? fcmToken;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission();
    fcmToken = await _messaging.getToken();
    // log(fcmToken ?? "null");
    onBackGroundMessage();
    onForegroundMessage();
    _messaging.subscribeToTopic("All_USERS");
  }

  static Future<void> onBackGroundMessage() async {
    FirebaseMessaging.onBackgroundMessage(_handler);
  }

  static onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(onData);
  }

  static onData(RemoteMessage message) async {
    LocalNotificationService.showBasicNotification(
      notificationModel: NotificationModel(
        id: message.messageId.hashCode,
        title: message.notification?.title.toString() ?? "null",
        body: message.notification?.body.toString() ?? "null",
        payload: message.data.toString(),
      ),
    );
    log(message.messageId.hashCode.toString());
  }

  static void setupNotificationListener() async {
    final lastProcessedTime = await _getLastProcessedTime();

    FirebaseFirestore.instance
        .collection('notifications')
        .where('timestamp',
            isGreaterThan:
                Timestamp.fromMillisecondsSinceEpoch(lastProcessedTime))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first;
        final data = latestDoc.data();
        final timestamp =
            (data['timestamp'] as Timestamp).millisecondsSinceEpoch;

        // Skip if already processed
        if (timestamp <= lastProcessedTime) return;

        final safeId = timestamp % 2147483647;

        LocalNotificationService.showBasicNotification(
          notificationModel: NotificationModel(
            id: safeId,
            title: data['title'] ?? 'إشعار جديد',
            body: data['body'] ?? 'يوجد تحديث جديد',
            payload: '',
          ),
        );

        // Save the new timestamp
        await _saveLastProcessedTime(timestamp);
      }
    });
  }

  static Future<void> _saveLastProcessedTime(int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastProcessedTime', timestamp);
  }

  static Future<int> _getLastProcessedTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastProcessedTime') ?? 0;
  }

  static Future<void> resetNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lastProcessedTime');
  }

  static Future<void> _handler(RemoteMessage message) async {
    // log(message.notification?.title.toString() ?? "null");
  }
}
