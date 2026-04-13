import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/reading_analysis.dart';
import '../screens/reading_analysis_screen.dart';

class AuthenticatedReadingService {
  static const String baseUrl = 'https://8q7ag381ui.execute-api.ap-northeast-2.amazonaws.com/prod/books';

  // 현재 로그인된 사용자의 독서 분석 가져오기
  static Future<ReadingAnalysis?> getCurrentUserAnalysis({int months = 6}) async {
    try {
      // Firebase Auth에서 현재 사용자 확인
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('사용자가 로그인되지 않았습니다');
      }

      print('Current user ID: ${user.uid}'); // 로그용

      // Lambda API 호출
      final uri = Uri.parse('$baseUrl?user_id=${user.uid}&months=$months');

      // Firebase ID Token 가져오기 (보안 강화 시 사용)
      final String? idToken = await user.getIdToken();

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken', // 필요시 사용
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // 에러 체크
        if (data.containsKey('analysis') && data['analysis'].containsKey('error')) {
          throw Exception('분석 오류: ${data['analysis']['error']}');
        }

        return ReadingAnalysis.fromJson(data);
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }

    } catch (e) {
      print('Error in getCurrentUserAnalysis: $e');
      rethrow;
    }
  }

  // 사용자 로그인 상태 확인
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // 현재 사용자 ID 가져오기
  static String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}

// 사용 예시 위젯
class ReadingAnalysisPage extends StatefulWidget {
  @override
  _ReadingAnalysisPageState createState() => _ReadingAnalysisPageState();
}

class _ReadingAnalysisPageState extends State<ReadingAnalysisPage> {
  ReadingAnalysis? analysisData;
  bool isLoading = true;
  String? errorMessage;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (!AuthenticatedReadingService.isUserLoggedIn()) {
        setState(() {
          errorMessage = '로그인이 필요합니다';
          isLoading = false;
        });
        return;
      }

      // 현재 사용자 ID 저장
      currentUserId = AuthenticatedReadingService.getCurrentUserId();

      final data = await AuthenticatedReadingService.getCurrentUserAnalysis();

      setState(() {
        analysisData = data;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF6C5CE7),
              ),
              SizedBox(height: 16),
              Text(
                '독서 분석 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                '오류 발생',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                ),
                child: Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (analysisData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.menu_book,
                color: Colors.white54,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                '분석할 독서 기록이 없습니다',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '독서 기록을 작성해보세요!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 정상 데이터가 있을 때는 기존의 ReadingAnalysisScreen UI 사용
    return ReadingAnalysisScreen(
      userId: currentUserId!, // 저장해둔 사용자 ID 사용
      initialData: analysisData, // 미리 로드한 데이터 전달
    );
  }
}