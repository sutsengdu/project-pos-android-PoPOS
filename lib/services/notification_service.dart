import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showLowStockNotification(String productName, int stock) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'low_stock_channel',
      'Low Stock Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0,
      'Low Stock Alert!',
      '$productName is low on stock ($stock left).',
      platformDetails,
    );
  }
}
