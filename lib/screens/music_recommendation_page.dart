import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class MusicRecommendationPage extends StatefulWidget {
  @override
  _MusicRecommendationPageState createState() => _MusicRecommendationPageState();
}

class _MusicRecommendationPageState extends State<MusicRecommendationPage> {
  final TextEditingController _bookController = TextEditingController();
  final FocusNode _bookFocusNode = FocusNode();
  List<Song> _recommendations = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;
  String _error = '';

  // API URLs
  static const String MUSIC_API_URL = 'https://ruhomixbzc.execute-api.ap-northeast-2.amazonaws.com/default/music_recommendation';
  static const String BOOK_SEARCH_URL = 'https://5m64hqj2f0.execute-api.ap-northeast-2.amazonaws.com/prod/search';

  // Colors
  static const _ivory  = Color(0xFFFFFCF5);
  static const _amber  = Color(0xFFFFB703);
  static const _orange = Color(0xFFFB8500);
  static const _cocoa  = Color(0xFF4E342E);
  static const _sand   = Color(0xFFFFE082);

  @override
  void initState() {
    super.initState();
    _bookController.addListener(_onBookTitleChanged);
    _bookFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _bookController.removeListener(_onBookTitleChanged);
    _bookController.dispose();
    _bookFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_bookFocusNode.hasFocus) {
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  void _onBookTitleChanged() {
    final query = _bookController.text.trim();
    if (query.length >= 2) {
      _getBookSuggestions(query);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _getBookSuggestions(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$BOOK_SEARCH_URL?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List books = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _suggestions = books.take(8).map<String>((book) =>
          book['title'] ?? ''
          ).where((title) => title.isNotEmpty).toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (e) {
      print('책 검색 실패: $e');
    } finally {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _bookController.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    _bookFocusNode.unfocus();
  }

  void _clearSearch() {
    _bookController.clear();
    setState(() {
      _showSuggestions = false;
      _error = '';
      _recommendations = [];
    });
  }

  Future<void> _getMusicRecommendations() async {
    if (_bookController.text.trim().isEmpty) {
      setState(() {
        _error = '책 제목을 입력해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
      _recommendations = [];
      _showSuggestions = false;
    });

    try {
      final response = await http.post(
        Uri.parse(MUSIC_API_URL),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'book_title': _bookController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          List<Song> songs = [];
          for (var item in data['recommendations']) {
            songs.add(Song.fromJson(item));
          }

          setState(() {
            _recommendations = songs;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['error'] ?? '알 수 없는 오류가 발생했습니다';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'API 호출 실패: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '네트워크 오류: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없습니다')),
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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
        body: GestureDetector(
          onTap: () {
            setState(() {
              _showSuggestions = false;
            });
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Column(
                children: [
                  // 검색 입력 영역
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.8),
                          _sand.withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 책 제목 입력창
                        TextField(
                          controller: _bookController,
                          focusNode: _bookFocusNode,
                          decoration: InputDecoration(
                            hintText: '책 제목을 입력하세요 (예: 1984, 해리포터, 데미안)',
                            prefixIcon: Icon(Icons.book, color: _amber),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isLoadingSuggestions)
                                  Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(_amber),
                                      ),
                                    ),
                                  ),
                                if (_bookController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.clear, color: _cocoa),
                                    onPressed: _clearSearch,
                                  ),
                              ],
                            ),
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
                          onSubmitted: (_) => _getMusicRecommendations(),
                          onTap: () {
                            if (_bookController.text.isNotEmpty) {
                              setState(() {
                                _showSuggestions = true;
                              });
                            }
                          },
                        ),

                        SizedBox(height: 16),

                        // 추천 받기 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _getMusicRecommendations,
                            icon: Icon(Icons.music_note),
                            label: Text(_isLoading ? '로딩 중...' : '음악 추천 받기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _amber,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 에러 메시지
                  if (_error.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 로딩 인디케이터
                  if (_isLoading)
                    Container(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: _amber),
                    ),

                  // 추천 결과 리스트
                  if (_recommendations.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _recommendations.length,
                        itemBuilder: (context, index) {
                          final song = _recommendations[index];
                          return SongCard(
                            song: song,
                            index: index + 1,
                            onLinkTap: _launchUrl,
                          );
                        },
                      ),
                    ),

                  // 빈 상태 메시지
                  if (!_isLoading && _recommendations.isEmpty && _error.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              '책 제목을 입력하고\n음악 추천을 받아보세요!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // 자동완성 제안 오버레이
              if (_showSuggestions && _suggestions.isNotEmpty)
                Positioned(
                  top: 140, // AppBar + 검색 입력창 위치 아래
                  left: 16,
                  right: 16,
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return InkWell(
                          onTap: () => _selectSuggestion(suggestion),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: index < _suggestions.length - 1
                                  ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.book, size: 18, color: _amber),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _cocoa,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(Icons.call_made, size: 16, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Song {
  final String title;
  final String artist;
  final String reason;
  final String mood;
  final Map<String, String> links;

  Song({
    required this.title,
    required this.artist,
    required this.reason,
    required this.mood,
    required this.links,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      reason: json['reason'] ?? '',
      mood: json['mood'] ?? '',
      links: Map<String, String>.from(json['links'] ?? {}),
    );
  }
}

class SongCard extends StatelessWidget {
  final Song song;
  final int index;
  final Function(String) onLinkTap;

  const SongCard({
    Key? key,
    required this.song,
    required this.index,
    required this.onLinkTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 곡 정보
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // 추천 이유
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💭 ${song.reason}',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            SizedBox(height: 8),

            // 장르/분위기
            Text(
              '🎵 ${song.mood}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 12),

            // 음악 서비스 링크 버튼들
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: song.links.entries.map((entry) {
                return _buildLinkButton(entry.key, entry.value);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkButton(String service, String url) {
    final serviceInfo = _getServiceInfo(service);

    return ElevatedButton.icon(
      onPressed: () => onLinkTap(url),
      icon: Icon(serviceInfo['icon'], size: 16),
      label: Text(
        serviceInfo['name'],
        style: TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: serviceInfo['color'],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size(0, 32),
      ),
    );
  }

  Map<String, dynamic> _getServiceInfo(String service) {
    switch (service) {
      case 'youtube':
        return {
          'name': 'YouTube',
          'icon': Icons.play_circle_filled,
          'color': Colors.red[600]
        };
      case 'spotify':
        return {
          'name': 'Spotify',
          'icon': Icons.library_music,
          'color': Colors.green[600]
        };
      case 'melon':
        return {
          'name': '멜론',
          'icon': Icons.music_note,
          'color': Colors.green[700]
        };
      case 'genie':
        return {
          'name': '지니',
          'icon': Icons.audiotrack,
          'color': Colors.orange[600]
        };
      case 'vibe':
        return {
          'name': 'VIBE',
          'icon': Icons.headphones,
          'color': Colors.purple[600]
        };
      default:
        return {
          'name': service,
          'icon': Icons.link,
          'color': Colors.grey[600]
        };
    }
  }
}