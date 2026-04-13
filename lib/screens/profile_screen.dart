

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gradu2/screens/reading_analysis_screen.dart';

import '../Services/reading_analysis_service.dart';

class ProfileScreen extends StatelessWidget {

  static const _ivory  = Color(0xFFFFFCF5); // 밝은 크림 배경
  static const _amber  = Color(0xFFFFB703); // 메인 옐로우
  static const _orange = Color(0xFFFB8500); // 버튼 포인트 오렌지
  static const _cocoa  = Color(0xFF4E342E); // 브라운 텍스트
  static const _sand   = Color(0xFFFFE082); // 연노랑 보조
  static const _error  = Colors.red;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFE186), // 밝은 옐로우
            Color(0xFFFFEDB9), // 크림톤
            Color(0xFFFFDAD6), // 살짝 핑크톤
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // 배경을 투명하게
        appBar: AppBar(
          backgroundColor: Colors.transparent, // AppBar도 투명하게
          elevation: 0, // 그림자 제거
          titleSpacing: 16,
          title: Row(
            children: [
              Image.asset(
                'assets/images/b_read.png',
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/bread.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '알림',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: _sand,
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? Icon(Icons.person, size: 50, color: _amber)
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      user?.isAnonymous == true
                          ? '임시 사용자'
                          : user?.displayName ?? '사용자',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      user?.email ?? '이메일 없음',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.bar_chart),
                    title: Text('독서 통계'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReadingAnalysisPage(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('설정'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('설정 기능은 추후 구현 예정입니다')),
                      );
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('로그아웃', style: TextStyle(color: Colors.red)),
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그아웃'),
        content: Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
            child: Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}