import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _diaryController = TextEditingController();
  List<dynamic> _recommendedBooks = [];
  Map<String, dynamic>? _emotionData; // 감정 분석 데이터 추가
  String _errorMessage = '';
  bool _isLoading = false;
  String? _selectedEmotion;

  // 색 팔레트
  static const _ivory  = Color(0xFFFFFCF5); // 밝은 크림 배경
  static const _amber  = Color(0xFFFFB703); // 메인 옐로우
  static const _orange = Color(0xFFFB8500); // 버튼 포인트 오렌지
  static const _cocoa  = Color(0xFF4E342E); // 브라운 텍스트
  static const _sand   = Color(0xFFFFE082); // 연노랑 보조
  static const _error  = Colors.red;

  // Flask 서버 URL (기존에 사용하던 것)
  final String _backendUrl = 'https://617b242cb73c.ngrok-free.app/recommend';

  // 감정 리스트
  final List<Map<String, dynamic>> _emotions = [
    {'name': '행복해', 'icon': '😊', 'color': Colors.orange},
    {'name': '슬퍼', 'icon': '😢', 'color': Colors.blue},
    {'name': '화나', 'icon': '😠', 'color': Colors.red},
    {'name': '걱정돼', 'icon': '😰', 'color': Colors.purple},
    {'name': '외로워', 'icon': '😔', 'color': Colors.grey},
    {'name': '스트레스 받아', 'icon': '😩', 'color': Colors.orange[800]},
    {'name': '피곤해', 'icon': '😴', 'color': Colors.indigo},
    {'name': '설레', 'icon': '😍', 'color': Colors.pink},
    {'name': '불안해', 'icon': '😨', 'color': Colors.amber[800]},
    {'name': '평온해', 'icon': '😌', 'color': Colors.green},
    {'name': '우울해', 'icon': '😞', 'color': Colors.blueGrey},
    {'name': '즐거워', 'icon': '😄', 'color': Colors.yellow[700]},
  ];

  // 일기 기반 추천
  Future<void> _sendDiaryAndGetRecommendations() async {
    setState(() {
      _isLoading = true;
      _recommendedBooks = [];
      _emotionData = null;
      _errorMessage = '';
      _selectedEmotion = null;
    });

    final userDiaryText = _diaryController.text.trim();
    if (userDiaryText.isEmpty) {
      setState(() {
        _errorMessage = '오늘의 일기를 입력해주세요!';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_diary': userDiaryText}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          // 책 추천 데이터 처리
          if (responseData is List) {
            _recommendedBooks = responseData;
          } else if (responseData['books'] != null) {
            _recommendedBooks = responseData['books'];
          } else if (responseData['book_recommendations'] != null) {
            _recommendedBooks = responseData['book_recommendations'];
          } else {
            _recommendedBooks = [];
          }

          // 감정 데이터 처리
          if (responseData is Map && responseData['emotions'] != null) {
            _emotionData = responseData['emotions'];
          } else if (responseData is Map && responseData['emotion_analysis'] != null) {
            _emotionData = responseData['emotion_analysis'];
          }
        });
      } else {
        setState(() {
          _errorMessage = '추천을 받는데 실패했습니다: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류 발생: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 감정 기반 추천
  Future<void> _getEmotionBasedRecommendations(String emotion) async {
    setState(() {
      _isLoading = true;
      _recommendedBooks = [];
      _emotionData = null;
      _errorMessage = '';
      _selectedEmotion = emotion;
    });

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_diary': emotion, 'emotion': emotion}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          // 책 추천 데이터 처리
          if (responseData is List) {
            _recommendedBooks = responseData;
          } else if (responseData['books'] != null) {
            _recommendedBooks = responseData['books'];
          } else if (responseData['book_recommendations'] != null) {
            _recommendedBooks = responseData['book_recommendations'];
          } else {
            _recommendedBooks = [];
          }

          // 감정 데이터 처리
          if (responseData is Map && responseData['emotions'] != null) {
            _emotionData = responseData['emotions'];
          } else if (responseData is Map && responseData['emotion_analysis'] != null) {
            _emotionData = responseData['emotion_analysis'];
          }
        });
      } else {
        setState(() {
          _errorMessage = '추천을 받는데 실패했습니다: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '네트워크 오류 발생: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 감정 분석 결과 표시 위젯
  Widget _buildEmotionAnalysis() {
    if (_emotionData == null) return SizedBox.shrink();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple, size: 24),
                SizedBox(width: 8),
                Text(
                  '🧠 감정 분석 결과',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // 주요 감정 표시
            if (_emotionData!['primary_emotion'] != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('😊', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text(
                      '주요 감정: ${_emotionData!['primary_emotion']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],

            // 감정 점수들 표시
            if (_emotionData!['scores'] != null) ...[
              Text(
                '감정 점수:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              ...(_emotionData!['scores'] as Map<String, dynamic>).entries.map((entry) {
                final emotion = entry.key;
                final score = entry.value;
                final percentage = (score * 100).round();

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          emotion,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: score,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getEmotionColor(emotion),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],

            // 기타 감정 데이터 표시
            if (_emotionData!['intensity'] != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '감정 강도: ${_emotionData!['intensity']}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            if (_emotionData!['sentiment'] != null) ...[
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '감정 경향: ${_emotionData!['sentiment']}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 감정에 따른 색상 반환
  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy': case 'happy': case '기쁨': case '행복':
      return Colors.yellow[700]!;
      case 'anger': case '분노': case '화남':
      return Colors.red;
      case 'sadness': case '슬픔': case '우울':
      return Colors.blue;
      case 'fear': case '두려움': case '불안':
      return Colors.purple;
      case 'surprise': case '놀람':
      return Colors.orange;
      case 'disgust': case '혐오':
      return Colors.brown;
      case 'neutral': case '중성': case '평온':
      return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }
  Widget _buildEmotionSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎭 지금 기분은?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _cocoa,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '현재 감정에 맞는 책을 추천해드려요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emotions.map((emotion) {
                final isSelected = _selectedEmotion == emotion['name'];
                return GestureDetector(
                  onTap: () => _getEmotionBasedRecommendations(emotion['name']),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? emotion['color'] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? emotion['color'] : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: emotion['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ] : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          emotion['icon'],
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(width: 6),
                        Text(
                          emotion['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // 책 카드 위젯 (이미지 포함)
  Widget _buildBookCard(Map<String, dynamic> book) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 표지 이미지
            Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: book['cover_url'] != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book['cover_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book, color: Colors.grey[400], size: 24),
                          Text('표지\n없음',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, color: Colors.grey[400], size: 24),
                  Text('표지\n없음',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 8, color: Colors.grey[500])),
                ],
              ),
            ),
            SizedBox(width: 16),

            // 책 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _cocoa,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    book['title'] ?? '제목 없음',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (book['author'] != null) ...[
                    SizedBox(height: 4),
                    Text(
                      '저자: ${book['author']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  if (book['reason'] != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Text(
                        '추천 이유: ${book['reason']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: _orange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _diaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 감정 선택 섹션
            _buildEmotionSelector(),

            SizedBox(height: 16),

            // 구분선
            Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),

            SizedBox(height: 16),

            // 일기 입력 섹션
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 오늘의 일기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _cocoa,
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _diaryController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: '오늘 하루는 어떠셨나요? 기분이나 생각을 자유롭게 적어보세요...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: _orange, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _sendDiaryAndGetRecommendations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('책을 찾고 있어요...'),
                          ],
                        )
                            : Text(
                          '📖 일기로 책 추천받기',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // 감정 분석 결과 표시
            _buildEmotionAnalysis(),

            // 감정 분석이 있을 때만 간격 추가
            if (_emotionData != null) SizedBox(height: 16),

            // 에러 메시지 표시
            if (_errorMessage.isNotEmpty)
              Card(
                color: Colors.red[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 추천 책 리스트 표시
            if (_recommendedBooks.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    '📚 추천 도서',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _cocoa,
                    ),
                  ),
                  if (_selectedEmotion != null) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _sand,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_selectedEmotion 감정',
                        style: TextStyle(
                          fontSize: 12,
                          color: _cocoa,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recommendedBooks.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final book = _recommendedBooks[index];
                  return _buildBookCard(book);
                },
              ),
            ],

            // 빈 상태 메시지
            if (!_isLoading && _recommendedBooks.isEmpty && _errorMessage.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      '감정을 선택하거나 일기를 작성하여\n책 추천을 받아보세요!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
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
}
