import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start the app immediately
  runApp(const GeoTrackApp());

  // Initialize Background Service in the background so it doesn't block the UI
  BackgroundTrackingService.initializeService();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
}

class GeoTrackApp extends StatelessWidget {
  const GeoTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoTrack Premium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF00D1FF),
          surface: const Color(0xFF14151B),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0B10),
        fontFamily: 'Roboto', // Use a clean sans-serif font
      ),
      home: const AuthScreen(),
    );
  }
}
