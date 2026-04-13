import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import '../widgets/book_card.dart';
import '../Services/csv_loader.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({Key? key}) : super(key: key);

  @override
  State<BookScreen> createState() => _CategorizedBookScreenState();
}

class _CategorizedBookScreenState extends State<BookScreen> {
  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  List<Book> _displayBooks = [];
  List<String> _categories = ['전체'];
  String _selectedCategory = '전체';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<dynamic> _searchResults = [];
  List<String> _suggestions = [];
  bool _isSearchMode = false;
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;
  String _searchErrorMessage = '';

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  int _totalPages = 0;
  bool _isLoading = false;

  static const _ivory  = Color(0xFFFFFCF5); // 밝은 크림 배경
  static const _amber  = Color(0xFFFFB703); // 메인 옐로우
  static const _orange = Color(0xFFFB8500); // 버튼 포인트 오렌지
  static const _cocoa  = Color(0xFF4E342E); // 브라운 텍스트
  static const _sand   = Color(0xFFFFE082); // 연노랑 보조
  static const _error  = Colors.red;

  final String _searchApiUrl = 'https://5m64hqj2f0.execute-api.ap-northeast-2.amazonaws.com/prod/search';

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _searchFocusNode.addListener(_onFocusChange);
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 기존 CSV 데이터 로딩
  void _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allBooks = await CsvLoader.loadBooksFromAws(
        'https://sm-book-review.s3.ap-northeast-2.amazonaws.com/cover/book_cover_info.csv',
      );

      _extractCategories();
      _filterBooksByCategory();

    } catch (e) {
      print('책 로딩 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _extractCategories() {
    Set<String> categorySet = {};
    for (Book book in _allBooks) {
      categorySet.add(book.category);
    }

    setState(() {
      _categories = ['전체', ...categorySet.toList()..sort()];
    });
  }

  void _filterBooksByCategory() {
    if (_selectedCategory == '전체') {
      _filteredBooks = List.from(_allBooks);
    } else {
      _filteredBooks = _allBooks.where((book) => book.category == _selectedCategory).toList();
    }

    _totalPages = (_filteredBooks.length / _itemsPerPage).ceil();
    if (_totalPages == 0) _totalPages = 1;

    if (_currentPage >= _totalPages) {
      _currentPage = 0;
    }

    _updateDisplayBooks();
  }

  void _updateDisplayBooks() {
    if (_filteredBooks.isEmpty) {
      setState(() {
        _displayBooks = [];
      });
      return;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _filteredBooks.length);

    setState(() {
      _displayBooks = _filteredBooks.sublist(startIndex, endIndex);
    });
  }

  // 검색 관련 메서드들
  void _onFocusChange() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      setState(() {
        _showSuggestions = true;
      });
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;
    if (query.length >= 2) {
      _getSuggestions(query);
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      // 로컬 CSV 데이터에서 자동완성 생성
      List<String> localSuggestions = _allBooks
          .where((book) =>
      book.title.toLowerCase().contains(query.toLowerCase()) ||
          book.author.toLowerCase().contains(query.toLowerCase()))
          .map((book) => book.title)
          .take(5)
          .toList();

      // API 자동완성도 추가 (임시 데이터)
      List<String> apiSuggestions = [
        'IT', '프로그래밍', 'AI', '머신러닝', 'Python', 'Flutter'
      ].where((suggestion) =>
          suggestion.toLowerCase().contains(query.toLowerCase())
      ).toList();

      setState(() {
        _suggestions = [...localSuggestions, ...apiSuggestions].take(8).toList();
        _showSuggestions = _suggestions.isNotEmpty;
      });

    } catch (e) {
      print('자동완성 로드 실패: $e');
    } finally {
      setState(() {
        _isLoadingSuggestions = false;
      });
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      _exitSearchMode();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchErrorMessage = '';
      _searchResults = [];
      _showSuggestions = false;
      _isSearchMode = true;
    });

    try {
      // 로컬 CSV 데이터에서 검색
      final localResults = _searchLocalBooks(_searchController.text.trim());

      // API에서 검색
      final apiResults = await _searchApiBooks(_searchController.text.trim());

      setState(() {
        _searchResults = [...apiResults];
      });

    } catch (e) {
      setState(() {
        _searchErrorMessage = '검색 중 오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  List<Map<String, dynamic>> _searchLocalBooks(String query) {
    return _allBooks
        .where((book) =>
    book.title.toLowerCase().contains(query.toLowerCase()) ||
        book.author.toLowerCase().contains(query.toLowerCase()) ||
        book.category.toLowerCase().contains(query.toLowerCase()))
        .map((book) => {
      'title': book.title,
      'author': book.author,
      'category': book.category,
      'source': 'local'
    })
        .toList();
  }

  Future<List<Map<String, dynamic>>> _searchApiBooks(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_searchApiUrl?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List apiBooks = jsonDecode(utf8.decode(response.bodyBytes));
        return apiBooks.map<Map<String, dynamic>>((book) => {
          ...book,
          'source': 'api'
        }).toList();
      }
    } catch (e) {
      print('API 검색 실패: $e');
    }
    return [];
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();
    _performSearch();
  }

  void _exitSearchMode() {
    setState(() {
      _isSearchMode = false;
      _searchResults = [];
      _searchErrorMessage = '';
      _showSuggestions = false;
    });
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void _onCategoryChanged(String category) {
    if (_isSearchMode) {
      _exitSearchMode();
    }

    setState(() {
      _selectedCategory = category;
      _currentPage = 0;
    });
    _filterBooksByCategory();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _totalPages && page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      _updateDisplayBooks();
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
            Color(0xFFFFE186),
            Color(0xFFFFEDB9),
            Color(0xFFFFDAD6),
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
          },
          child: Column(
            children: [
              // 검색 입력 영역
              Container(
                margin: EdgeInsets.all(16), //padding을 margin으로 변경
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  //그라데이션과 조화되는 반투명 배경
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      _sand.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16), //둥근 모서리 추가
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
                    // 검색 입력창
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: '책 제목, 저자, 카테고리로 검색하세요...',
                        prefixIcon: Icon(Icons.search, color: _amber),
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
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.clear, color: _cocoa),
                                onPressed: _exitSearchMode,
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
                        fillColor: Colors.white.withOpacity(0.9), //반투명한 흰색 배경
                      ),
                      onSubmitted: (_) => _performSearch(),
                      onTap: () {
                        // 검색 모드가 아닐 때만 자동완성 표시
                        if (_searchController.text.isNotEmpty && !_isSearchMode) {
                          setState(() {
                            _showSuggestions = true;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 12),

                    // 검색 버튼
                    if (_searchController.text.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _performSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _amber,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSearching
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('검색 중...'),
                            ],
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 18),
                              SizedBox(width: 6),
                              Text('통합 검색', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 자동완성 제안 영역
              if (_showSuggestions && _suggestions.isNotEmpty)
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                          child: Row(
                            children: [
                              Icon(Icons.search, size: 18, color: Colors.grey[600]),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: TextStyle(fontSize: 14),
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

              // 검색 모드가 아닐 때만 카테고리 바 표시
              if (!_isSearchMode) ...[
                // 카테고리 선택 바
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      final bookCount = category == '전체'
                          ? _allBooks.length
                          : _allBooks.where((book) => book.category == category).length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('$category ($bookCount)'),
                          selected: isSelected,
                          onSelected: (_) => _onCategoryChanged(category),
                          backgroundColor: Colors.white,
                          selectedColor: _amber,
                          checkmarkColor: _cocoa,
                          labelStyle: TextStyle(
                            color: isSelected ? _cocoa : _amber,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 현재 상태 정보
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: _sand,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_selectedCategory: ${_filteredBooks.length}권',
                        style: TextStyle(
                          color: _cocoa,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_totalPages > 1)
                        Text(
                          '${_currentPage + 1} / $_totalPages 페이지',
                          style: TextStyle(
                            color: _cocoa,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // 검색 모드일 때 결과 정보
              if (_isSearchMode)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: _sand,
                  child: Row(
                    children: [
                      Icon(Icons.search_outlined, size: 20, color: _cocoa),
                      SizedBox(width: 8),
                      Text(
                        '검색 결과: ${_searchResults.length}개',
                        style: TextStyle(
                          color: _cocoa,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      TextButton(
                        onPressed: _exitSearchMode,
                        child: Text('검색 종료', style: TextStyle(color: _cocoa)),
                      ),
                    ],
                  ),
                ),

              // 에러 메시지
              if (_searchErrorMessage.isNotEmpty)
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _searchErrorMessage,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              // 메인 콘텐츠 영역
              Expanded(
                child: _buildMainContent(),
              ),

              // 페이지네이션 (검색 모드가 아닐 때만)
              if (!_isSearchMode && _totalPages > 1) _buildPaginationBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('책 데이터를 불러오는 중...'),
          ],
        ),
      );
    }

    if (_isSearchMode) {
      return _buildSearchResults();
    } else {
      return _buildCategoryResults();
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              '검색 결과가 없습니다',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              '다른 키워드로 검색해보세요',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return _buildSearchResultCard(item);
      },
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> item) {
    final isLocal = item['source'] == 'local';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 표지
            Container(
              width: 60,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: item['book_cover_url'] != null && item['book_cover_url'].isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['book_cover_url'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _amber.withOpacity(0.1),
                      child: Icon(Icons.menu_book, size: 30, color: _amber),
                    );
                  },
                ),
              )
                  : Container(
                decoration: BoxDecoration(
                  color: _amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.menu_book, size: 30, color: _amber),
              ),
            ),

            SizedBox(width: 12),

            // 책 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 출처 표시
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? '제목 없음',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _cocoa,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLocal ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isLocal ? '로컬' : 'API',
                          style: TextStyle(
                            fontSize: 10,
                            color: isLocal ? Colors.green[700] : Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),

                  // 저자
                  if (item['author'] != null)
                    Text(
                      '저자: ${item['author']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),

                  SizedBox(height: 4),

                  // 카테고리
                  if (item['category'] != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['category'],
                        style: TextStyle(
                          fontSize: 10,
                          color: _cocoa,
                          fontWeight: FontWeight.bold,
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

  Widget _buildCategoryResults() {
    if (_allBooks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('데이터가 없습니다.'),
          ],
        ),
      );
    }

    if (_displayBooks.isEmpty) {
      return Center(
        child: Text(
          '$_selectedCategory 카테고리에 책이 없습니다.',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _displayBooks.length,
      itemBuilder: (context, index) {
        return BookCard(book: _displayBooks[index]);
      },
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 페이지 버튼
          ElevatedButton.icon(
            onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('이전'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _sand,
              foregroundColor: _amber,
            ),
          ),

          // 페이지 번호들
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPageNumbers(),
            ),
          ),

          // 다음 페이지 버튼
          ElevatedButton.icon(
            onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('다음'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _sand,
              foregroundColor: _amber,
            ),
          ),
        ],
      ),
    );
  }


  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];

    int start = (_currentPage - 2).clamp(0, _totalPages - 5).clamp(0, _totalPages);
    int end = (start + 5).clamp(5, _totalPages);

    if (start > 0) {
      pageNumbers.add(_buildPageButton(0));
      if (start > 1) {
        pageNumbers.add(const Text('...', style: TextStyle(color: Colors.grey)));
      }
    }

    for (int i = start; i < end; i++) {
      pageNumbers.add(_buildPageButton(i));
    }

    if (end < _totalPages) {
      if (end < _totalPages - 1) {
        pageNumbers.add(const Text('...', style: TextStyle(color: Colors.grey)));
      }
      pageNumbers.add(_buildPageButton(_totalPages - 1));
    }

    return pageNumbers;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () => _goToPage(page),
        style: TextButton.styleFrom(
          backgroundColor: isCurrentPage ? _amber : Colors.transparent,
          foregroundColor: isCurrentPage ? Colors.white : _amber,
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          '${page + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}