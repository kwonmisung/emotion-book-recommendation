import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gradu2/screens/auth_wrapper.dart';
import 'package:gradu2/screens/log_screen.dart';
import 'package:gradu2/screens/profile_screen.dart';
import 'package:gradu2/screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/book_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  try {
    await Firebase.initializeApp();
    print('Firebase 초기화 성공');
  } catch (e) {
    print('Firebase 초기화 실패: $e');
  }

  runApp(BreadApp());
}


class BreadApp extends StatelessWidget {
  const BreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bread',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
      ),
      home: SplashScreen(),
    );
  }
}