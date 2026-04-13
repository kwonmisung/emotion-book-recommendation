import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gradu2/screens/log_screen.dart';
import 'package:gradu2/screens/profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/book_screen.dart';
import '../firebase_options.dart';
import 'music_recommendation_page.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _navIndex = 0;

  // 앱 컬러 팔레트
  static const _ivory  = Color(0xFFFFFCF5); // 밝은 크림 배경
  static const _amber  = Color(0xFFFFB703); // 메인 옐로우
  static const _orange = Color(0xFFFB8500); // 버튼 포인트 오렌지
  static const _cocoa  = Color(0xFF4E342E); // 브라운 텍스트
  static const _sand   = Color(0xFFFFE082); // 연노랑 보조

  final List<Widget> _pages = [
    HomeScreen(),
    MusicRecommendationPage(),
    BookScreen(),
    LogScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'bread.app',
      theme: ThemeData(
        // 메인 색상 테마 설정
        primarySwatch: MaterialColor(0xFFFFB703, {
          50: Color(0xFFFFF9E6),
          100: Color(0xFFFFF0C2),
          200: Color(0xFFFFE699),
          300: Color(0xFFFFDC70),
          400: Color(0xFFFFD152),
          500: Color(0xFFFFB703), // 메인 컬러
          600: Color(0xFFE5A503),
          700: Color(0xFFCC9202),
          800: Color(0xFFB27F02),
          900: Color(0xFF996C01),
        }),

        // AppBar 테마
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: _cocoa),
          titleTextStyle: TextStyle(color: _cocoa, fontSize: 18, fontWeight: FontWeight.bold),
        ),

        // 버튼 테마
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _amber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // 텍스트 버튼 테마
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _amber,
          ),
        ),

        // 입력 필드 테마
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _amber.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _amber, width: 2),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
        ),

        // 카드 테마
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // 색상 스키마
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(0xFFFFB703, {
            50: Color(0xFFFFF9E6),
            100: Color(0xFFFFF0C2),
            200: Color(0xFFFFE699),
            300: Color(0xFFFFDC70),
            400: Color(0xFFFFD152),
            500: Color(0xFFFFB703),
            600: Color(0xFFE5A503),
            700: Color(0xFFCC9202),
            800: Color(0xFFB27F02),
            900: Color(0xFF996C01),
          }),
        ).copyWith(
          secondary: _orange,
          background: _ivory,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: _cocoa,
          onSurface: _cocoa,
        ),

        // 스낵바 테마
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _amber,
          contentTextStyle: TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: Scaffold(
        body: _pages[_navIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: _sand.withOpacity(0.3),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '홈',
            ),
            NavigationDestination(
              icon: Icon(Icons.music_note_outlined),
              selectedIcon: Icon(Icons.music_note),
              label: '노래추천',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: '탐색',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: '서재',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}