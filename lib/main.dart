import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacknovax/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF030814),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const StackNovaXApp());
}

class StackNovaXApp extends StatelessWidget {
  const StackNovaXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackNovaX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'monospace',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          surface: Color(0xFF050D20),
        ),
        scaffoldBackgroundColor: const Color(0xFF030814),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const SplashScreen(),
    );
  }
}