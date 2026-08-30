import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/khata_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';

import 'utils/notification_helper.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized prior to loading settings files
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationHelper.init();
  } catch (e) {
    debugPrint("Notification init error: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KhataProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<KhataProvider>(
      builder: (context, khataProvider, child) {
        return MaterialApp(
          title: 'Premium Khata Book',
          debugShowCheckedModeBanner: false,
          
          // Theme configurations
          themeMode: khataProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          
          // Initial Screen
          home: const SplashScreen(),
        );
      },
    );
  }
}
