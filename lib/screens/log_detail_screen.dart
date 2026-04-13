import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/log.dart';

class LogDetailScreen extends StatelessWidget {
  final ReadingLog log;

  static const _ivory  = Color(0xFFFFFCF5); // 밝은 크림 배경
  static const _amber  = Color(0xFFFFB703); // 메인 옐로우
  static const _orange = Color(0xFFFB8500); // 버튼 포인트 오렌지
  static const _cocoa  = Color(0xFF4E342E); // 브라운 텍스트
  static const _sand   = Color(0xFFFFE082); // 연노랑 보조
  static const _error  = Colors.red;

  const LogDetailScreen({Key? key, required this.log}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('독서 기록 상세'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // 공유 기능 구현 가능
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('공유 기능은 추후 구현 예정입니다')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _sand,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DateFormat('yyyy.MM.dd').format(log.date),
                            style: TextStyle(
                              color: _orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      log.logTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.book, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          log.bookTitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: _orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          log.author,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '독서 기록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  log.content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기록 정보',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '작성일: ${DateFormat('yyyy년 M월 d일 HH:mm').format(log.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}