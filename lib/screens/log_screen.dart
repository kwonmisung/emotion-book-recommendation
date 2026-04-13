import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/log.dart';
import 'add_log_screen.dart';
import 'log_detail_screen.dart';

class LogScreen extends StatefulWidget {
  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  static const _ivory  = Color(0xFFFFFCF5); // 밝은 크림 배경
  static const _amber  = Color(0xFFFFB703); // 메인 옐로우
  static const _orange = Color(0xFFFB8500); // 버튼 포인트 오렌지
  static const _cocoa  = Color(0xFF4E342E); // 브라운 텍스트
  static const _sand   = Color(0xFFFFE082); // 연노랑 보조
  static const _error  = Colors.red;

  Future<void> _deleteLog(ReadingLog log) async {
    // 삭제 확인 다이얼로그
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: _error, size: 28),
              SizedBox(width: 8),
              Text('독서 기록 삭제'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('정말로 이 독서 기록을 삭제하시겠습니까?'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.logTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _cocoa,
                      ),
                    ),
                    Text(
                      '${log.bookTitle} - ${log.author}',
                      style: TextStyle(
                        color: _amber,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                '삭제된 기록은 복구할 수 없습니다.',
                style: TextStyle(
                  color: _error,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _error,
                foregroundColor: Colors.white,
              ),
              child: Text('삭제'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await _firestore
            .collection('reading_logs')
            .doc(log.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('독서 기록이 삭제되었습니다'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('삭제 중 오류가 발생했습니다: $e')),
              ],
            ),
            backgroundColor: _error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _editLog(ReadingLog log) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLogScreen(editingLog: log), // 수정용으로 기존 로그 전달
      ),
    );

    if (result == true) {
      // 수정 완료 후 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('독서 기록이 수정되었습니다'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('reading_logs')
              .where('userId', isEqualTo: _currentUserId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Firestore Error: ${snapshot.error}');
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(
                        '데이터베이스 오류',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final logs = snapshot.data!.docs
                .map((doc) => ReadingLog.fromFirestore(doc))
                .toList();

            if (logs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildSwipeableLogCard(log);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddLogScreen()),
            );
          },
          backgroundColor: _amber,
          child: Icon(Icons.add, color: Colors.white),
          tooltip: '새 독서 기록 추가',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('아직 독서 기록이 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('+ 버튼을 눌러 첫 번째 기록을 추가해보세요!',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSwipeableLogCard(ReadingLog log) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // 스와이프 삭제 확인
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('삭제 확인'),
              content: Text('이 독서 기록을 삭제하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: _error),
                  child: Text('삭제', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await _firestore
              .collection('reading_logs')
              .doc(log.id)
              .delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('독서 기록이 삭제되었습니다'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '취소',
                onPressed: () {
                  // 실제로는 복구 기능 구현 필요
                },
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 중 오류가 발생했습니다'),
              backgroundColor: _error,
            ),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              '삭제',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      child: _buildLogCard(log),
    );
  }

  Widget _buildLogCard(ReadingLog log) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LogDetailScreen(log: log),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _amber,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.logTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${log.bookTitle} - ${log.author}',
                          style: TextStyle(
                            fontSize: 14,
                            color: _amber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          log.content,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 수정 버튼
                      GestureDetector(
                        onTap: () => _editLog(log),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: _amber,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        DateFormat('MM.dd').format(log.date),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('yyyy').format(log.date),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}