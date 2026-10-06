import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelId = 'habitrak_streak_channel';
  static const String channelName = 'Habitrak Streak & Mindfulness';
  static const String channelDescription =
      'Alerts and reminders when your habit or mindfulness streak is at risk';

  static const List<Map<String, String>> coolStreakMessages = [
    {
      'title': '🔥 Streak Rescue: Don\'t Break the Chain!',
      'body':
          'Your habits and Mindful Zen Garden need you today. 2 minutes is all it takes to keep your 7-day flame alive 🌱',
    },
    {
      'title': '🌿 Zen Garden Calling: Unwind & Restore',
      'body':
          'Mind feeling cluttered? Place today\'s stones in your Zen Mosaic and reclaim tranquil focus ✨',
    },
    {
      'title': '⚡ Streak Rescue Mission!',
      'body':
          'You\'re 1 harmonious mosaic piece away from protecting your momentum. Breathe, align, and conquer!',
    },
    {
      'title': '🍃 Stillness in Motion',
      'body':
          'A gentle nudge from Habitrak: Your habits shape your future self. Keep your streak glowing before midnight 🌙',
    },
    {
      'title': '✨ Vitality Boost Waiting',
      'body':
          'Your Mindful Garden has +15 Vitality and peace of mind reserved for you today. Step into harmony 🧘',
    },
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization error: $e');
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    // Create high importance notification channel on Android
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isIOS || Platform.isMacOS) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final result = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final result =
          await androidImplementation?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  NotificationDetails _buildNotificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('app_logo'),
          color: Color(0xFF38573E),
          styleInformation: BigTextStyleInformation(''),
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );
  }

  /// Sends an immediate cool streak alert with the app logo
  Future<void> showStreakWarningNotification({
    int streak = 7,
    String? reason,
  }) async {
    await initialize();

    final messageIndex = (DateTime.now().day) % coolStreakMessages.length;
    final message = coolStreakMessages[messageIndex];

    final title = '🔥 Streak Alert: Keep your $streak-day momentum alive!';
    final body =
        reason ??
        '${message['body']} • Jump into the Mindful Garden Puzzle to stay unbroken.';

    await _notificationsPlugin.show(
      id: 1001,
      title: title,
      body: body,
      notificationDetails: _buildNotificationDetails(),
      payload: 'streak_reminder',
    );
  }

  /// Trigger test notification immediately to let user verify logo and cool wording
  Future<void> showTestStreakNotification({int streak = 7}) async {
    await initialize();
    await requestPermissions();

    await _notificationsPlugin.show(
      id: 9999,
      title: '🔥 Habitrak Streak Saved! (7-Day Momentum)',
      body:
          '✨ "Patience is the calm acceptance of things in order." Your Mindful Garden is thriving 🌱',
      notificationDetails: _buildNotificationDetails(),
      payload: 'mindful_garden_puzzle',
    );
  }

  /// Schedules daily evening streak check if streak is not completed
  Future<void> scheduleDailyStreakCheckNotification({
    int streak = 7,
    int hour = 20, // 8:00 PM
    int minute = 0,
  }) async {
    await initialize();

    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        id: 2001,
        title: '🔥 Evening Streak Check: 1 Puzzle Away!',
        body:
            'You haven\'t completed today\'s Zen Garden puzzle. Take a 2-minute mindful pause before your streak resets 🧘',
        scheduledDate: scheduledDate,
        notificationDetails: _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'evening_streak_alert',
      );
    } catch (e) {
      debugPrint('Error scheduling streak notification: $e');
    }
  }

  /// Cancel all streak-related notifications (e.g. when completed for the day)
  Future<void> cancelStreakNotifications() async {
    await _notificationsPlugin.cancel(id: 1001);
    await _notificationsPlugin.cancel(id: 2001);
  }
}
