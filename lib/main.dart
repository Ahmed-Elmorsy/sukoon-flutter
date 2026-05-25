import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/auth/choose_language_screen.dart';
import 'services/app_logger.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'services/auth_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
    } catch (_) {}
  }
  await AppLogger.instance.init();
  try {
    await NotificationService.instance.init();
    // Handle FCM token refresh - save new token to backend when it changes
    NotificationService.instance.onTokenRefresh = (newToken) async {
      if (AuthSession.instance.token.isNotEmpty) {
        await ApiService.saveFcmToken(AuthSession.instance.token, newToken);
      }
    };
  } catch (_) {}
  AppLogger.instance.info('APP', 'Skoon starting');
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const SkoonApp());
}

class SkoonApp extends StatelessWidget {
  const SkoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skoon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const ChooseLanguageScreen(),
    );
  }
}
