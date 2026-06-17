import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'screens/ble_wifi_setup_page.dart';
import 'services/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Non-fatal: BLE Wi-Fi setup must work even if Firebase isn't configured.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const PawMeApp(),
    ),
  );
}

class PawMeApp extends StatelessWidget {
  const PawMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'PawMe',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: themeProvider.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      // TEMP: skip auth — launch straight into BLE Wi-Fi provisioning for bring-up.
      // Restore `const SplashScreen()` (import screens/splash_screen.dart) for the full flow.
      home: const BleWifiSetupPage(),
    );

  }
}
