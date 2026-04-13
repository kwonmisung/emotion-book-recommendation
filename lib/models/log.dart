import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingLog {
  final String id;
  final String userId; // 사용자 ID 추가
  final String bookTitle;
  final String author;
  final DateTime date;
  final String logTitle;
  final String content;
  final DateTime createdAt;

  ReadingLog({
    required this.id,
    required this.userId,
    required this.bookTitle,
    required this.author,
    required this.date,
    required this.logTitle,
    required this.content,
    required this.createdAt,
  });

  factory ReadingLog.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ReadingLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      author: data['author'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      logTitle: data['logTitle'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId, // 사용자 ID 포함
      'bookTitle': bookTitle,
      'author': author,
      'date': Timestamp.fromDate(date),
      'logTitle': logTitle,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}