import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/log.dart';

class AddLogScreen extends StatefulWidget {
  final ReadingLog? editingLog; // 편집할 로그 (null이면 새 로그 생성)

  AddLogScreen({this.editingLog}); // 생성자에 추가

  @override
  _AddLogScreenState createState() => _AddLogScreenState();
}


class _AddLogScreenState extends State<AddLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookTitleController = TextEditingController();
  final _authorController = TextEditingController();
  final _logTitleController = TextEditingController();
  final _contentController = TextEditingController();
  final _bookTitleFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isSearching = false;
  bool _showBookSuggestions = false;
  List<Map<String, dynamic>> _bookSuggestions = [];

  // API URL
  final String _bookSearchUrl = 'https://5m64hqj2f0.execute-api.ap-northeast-2.amazonaws.com/prod/search';

  static const _ivory  = Color(0xFFFFFCF5);
  static const _amber  = Color(0xFFFFB703);
  static const _orange = Color(0xFFFB8500);
  static const _cocoa  = Color(0xFF4E342E);
  static const _sand   = Color(0xFFFFE082);
  static const _error  = Colors.red;

  @override
  void initState() {
    super.initState();

    // 편집 모드인 경우 기존 데이터로 초기화
    if (widget.editingLog != null) {
      _bookTitleController.text = widget.editingLog!.bookTitle;
      _authorController.text = widget.editingLog!.author;
      _logTitleController.text = widget.editingLog!.logTitle;
      _contentController.text = widget.editingLog!.content;
      _selectedDate = widget.editingLog!.date;
    }

    _bookTitleController.addListener(_onBookTitleChanged);
    _bookTitleFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _bookTitleController.removeListener(_onBookTitleChanged);
    _bookTitleController.dispose();
    _authorController.dispose();
    _logTitleController.dispose();
    _contentController.dispose();
    _bookTitleFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_bookTitleFocusNode.hasFocus) {
      // 포커스를 잃으면 잠시 후 자동완성 숨김
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showBookSuggestions = false;
          });
        }
      });
    }
  }

  void _onBookTitleChanged() {
    final query = _bookTitleController.text.trim();
    if (query.length >= 2) {
      _searchBooks(query);
    } else {
      setState(() {
        _bookSuggestions = [];
        _showBookSuggestions = false;
      });
    }
  }

  Future<void> _searchBooks(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_bookSearchUrl?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List books = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _bookSuggestions = books.take(5).map<Map<String, dynamic>>((book) => {
            'title': book['title'] ?? '',
            'author': book['author'] ?? '',
            'category': book['category'] ?? '',
            'book_cover_url': book['book_cover_url'] ?? '',
          }).toList();
          _showBookSuggestions = _bookSuggestions.isNotEmpty;
        });
      }
    } catch (e) {
      print('책 검색 실패: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectBook(Map<String, dynamic> book) {
    // 리스너 일시 제거 (검색 방지)
    _bookTitleController.removeListener(_onBookTitleChanged);

    setState(() {
      _bookTitleController.text = book['title'];
      _authorController.text = book['author'];
      _showBookSuggestions = false;
    });

    _bookTitleFocusNode.unfocus();

    // 리스너 다시 추가 (약간의 지연 후)
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _bookTitleController.addListener(_onBookTitleChanged);
      }
    });

    // 작가 정보 자동 입력 알림
    if (book['author'].isNotEmpty) {
      // 약간의 지연 후 스낵바 표시 (자동완성 창이 완전히 사라진 후)
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('작가 정보가 자동으로 입력되었습니다: ${book['author']}'),
              duration: Duration(seconds: 2),
              backgroundColor: _amber,
            ),
          );
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
      helpText: '날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveLog() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final log = ReadingLog(
        id: widget.editingLog?.id ?? '',
        userId: currentUser.uid,
        bookTitle: _bookTitleController.text.trim(),
        author: _authorController.text.trim(),
        date: _selectedDate,
        logTitle: _logTitleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: widget.editingLog?.createdAt ?? DateTime.now(),
      );

      if (widget.editingLog != null) {
        // 편집 모드: 기존 문서 업데이트
        await FirebaseFirestore.instance
            .collection('reading_logs')
            .doc(widget.editingLog!.id)
            .update(log.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('독서 기록이 수정되었습니다!')),
        );
      } else {
        // 생성 모드: 새 문서 추가
        await FirebaseFirestore.instance
            .collection('reading_logs')
            .add(log.toFirestore());
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(widget.editingLog != null ? '독서 기록이 수정되었습니다!' : '독서 기록이 저장되었습니다!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 잠시 후 이전 화면으로 이동
        await Future.delayed(Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true);
        }
      }

    } catch (e) {
      print('저장 오류: $e');

      // 에러 발생 - 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('저장 중 오류가 발생했습니다: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새 독서 기록 추가'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveLog,
            child: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              '저장',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(  // GestureDetector를 Stack으로 변경
        children: [
          // 메인 콘텐츠
          GestureDetector(
            onTap: () {
              setState(() {
                _showBookSuggestions = false;
              });
              FocusScope.of(context).unfocus();
            },
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('책 정보'),
                    SizedBox(height: 8),

                    // 책 제목 입력 (Stack 제거)
                    _buildBookTitleField(),

                    SizedBox(height: 16), // 고정된 간격

                    _buildTextField(
                      controller: _authorController,
                      label: '작가',
                      hint: '책을 선택하면 자동으로 입력됩니다',
                      icon: Icons.person,
                      isRequired: false,
                    ),
                    SizedBox(height: 24),
                    _buildSectionTitle('기록 정보'),
                    SizedBox(height: 8),
                    _buildDateSelector(),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _logTitleController,
                      label: '기록 제목',
                      hint: '독서 기록의 제목을 입력하세요',
                      icon: Icons.title,
                    ),
                    SizedBox(height: 16),
                    _buildTextField(
                      controller: _contentController,
                      label: '독서 기록 내용',
                      hint: '독서 후 느낀 점, 인상 깊은 구절, 생각 등을 자유롭게 작성하세요',
                      icon: Icons.edit_note,
                      maxLines: 8,
                      isRequired: true,
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveLog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _amber,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                            Text(
                              '저장 중...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                            : Text(
                          '독서 기록 저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 자동완성 오버레이 (위에 떠있음)
          if (_showBookSuggestions && _bookSuggestions.isNotEmpty)
            Positioned(
              top: 130, // AppBar + 패딩 + 섹션제목 + 책제목필드 위치
              left: 16,
              right: 16,
              child: _buildBookSuggestions(),
            ),
        ],
      ),
    );
  }

  Widget _buildBookTitleField() {
    return TextFormField(
      controller: _bookTitleController,
      focusNode: _bookTitleFocusNode,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: '책 제목',
        hintText: '책 제목을 입력하면 자동완성됩니다',
        prefixIcon: Icon(Icons.book),
        suffixIcon: _isSearching
            ? Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _orange!, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '책 제목을 입력해주세요';
        }
        return null;
      },
      onTap: () {
        if (_bookTitleController.text.isNotEmpty) {
          setState(() {
            _showBookSuggestions = true;
          });
        }
      },
    );
  }

  Widget _buildBookSuggestions() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _bookSuggestions.length,
          itemBuilder: (context, index) {
            final book = _bookSuggestions[index];
            return InkWell(
              onTap: () => _selectBook(book),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: index < _bookSuggestions.length - 1
                      ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                      : null,
                ),
                child: Row(
                  children: [
                    // 책 표지 아이콘 또는 이미지
                    Container(
                      width: 40,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _amber.withOpacity(0.3)),
                      ),
                      child: book['book_cover_url'] != null && book['book_cover_url'].isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          book['book_cover_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.book, color: _amber, size: 20);
                          },
                        ),
                      )
                          : Icon(Icons.book, color: _amber, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _cocoa,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (book['author'].isNotEmpty) ...[
                            SizedBox(height: 2),
                            Text(
                              '저자: ${book['author']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (book['category'].isNotEmpty) ...[
                            SizedBox(height: 2),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _sand.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                book['category'],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _cocoa,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: !_isLoading,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _orange!, width: 2),
        ),
      ),
      validator: isRequired ? (value) {
        if (value == null || value.trim().isEmpty) {
          return '${label}을(를) 입력해주세요';
        }
        return null;
      } : null,
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _isLoading ? null : () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '날짜',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  DateFormat('yyyy년 M월 d일').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Spacer(),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}