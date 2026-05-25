import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Debug print helper
void debugPrint(String message) {
  developer.log(message, name: 'NotificationService');
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'rentease_notifications',
    'RentEase Notifications',
    description: 'Apartment and contract updates',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (!_isMobile) {
      debugPrint('🔧 DEBUG: Running on desktop - FCM tokens will be simulated');
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    FirebaseMessaging.onMessage.listen(_showLocal);
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await onTokenRefresh?.call(newToken);
      } catch (_) {}
    });
  }

  Future<void> Function(String)? onTokenRefresh;

  /// Debug flag to enable fake FCM tokens on Windows for testing
  static bool debugWindowsToken = true;

  Future<String?> getToken() async {
    if (!_isMobile) {
      // Debug mode: generate fake token for Windows testing
      if (debugWindowsToken && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final fakeToken = 'windows_debug_token_${DateTime.now().millisecondsSinceEpoch}';
        debugPrint('🔧 DEBUG: Generated fake FCM token for Windows: $fakeToken');
        return fakeToken;
      }
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  void _showLocal(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
