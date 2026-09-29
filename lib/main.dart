import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'screens/home_screen.dart';
import 'screens/overlay_screen.dart';

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MrKokoApp());
}

class MrKokoApp extends StatelessWidget {
  const MrKokoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MR KOKO Signal Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020408),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
