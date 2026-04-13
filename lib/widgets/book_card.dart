import 'package:flutter/material.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 표지 이미지
            Container(
              width: 60,
              height: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _buildBookCover(),
              ),
            ),

            // 책 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 저자
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 카테고리 태그
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(book.category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      book.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildBookCover() {
    if (book.imageUrl != null && book.imageUrl!.isNotEmpty) {
      return Image.network(
        book.imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue[300],
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultIcon();
        },
        cacheWidth: 120,
      );
    } else {
      return _buildDefaultIcon();
    }
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.book,
        size: 30,
        color: Colors.grey[400],
      ),
    );
  }

  // 카테고리별 색상 지정
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case '소설/시/희곡':
      case 'novel':
        return Colors.purple[400]!;
      case '판타지':
      case 'fantasy':
        return Colors.indigo[400]!;
      case 'sf':
      case '인문':
        return Colors.cyan[400]!;
      case '로맨스':
      case 'romance':
        return Colors.pink[400]!;
      case '미스테리':
      case 'mystery':
        return Colors.grey[600]!;
      case '여행':
      case 'thriller':
        return Colors.red[400]!;
      case '자기계발':
      case 'self-help':
        return Colors.green[400]!;
      case 'IT':
      case 'it':
        return Colors.brown[400]!;
      case '에세이':
      case 'philosophy':
        return Colors.deepPurple[400]!;
      case '과학':
      case 'science':
        return Colors.blue[400]!;
      case '예술':
      case 'art':
        return Colors.orange[400]!;
      case '건강/취미':
      case 'fairy tale':
        return Colors.lime[400]!;
      case '고전':
      case 'classic':
        return Colors.amber[600]!;
      case '공상과학':
      case 'sf':
        return Colors.teal[400]!;
      case '기술':
      case 'technology':
        return Colors.lightBlue[400]!;
      default:
        return Colors.grey[400]!;
    }
  }
}