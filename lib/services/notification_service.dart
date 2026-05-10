import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const AndroidNotificationChannel _announcementChannel =
      AndroidNotificationChannel(
        'announcements',
        'Announcements',
        description: 'System announcements and BMoris updates',
        importance: Importance.high,
      );

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();

      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      await messaging.subscribeToTopic('announcements');

      final token = await messaging.getToken();
      developer.log('FCM token: ${token ?? "null"}');

      FirebaseMessaging.onMessage.listen((message) {
        developer.log(
          'FCM foreground message: ${message.notification?.title ?? ""}',
        );
        _showForegroundNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        developer.log(
          'FCM opened message: ${message.notification?.title ?? ""}',
        );
      });
    } on MissingPluginException catch (e) {
      developer.log('FCM plugin unavailable in this build: $e');
    } catch (e) {
      developer.log('FCM init skipped: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(settings: initializationSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_announcementChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'BMoris';
    final body =
        notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        'You have a new notification.';

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _announcementChannel.id,
          _announcementChannel.name,
          channelDescription: _announcementChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.messageId,
    );
  }
}
