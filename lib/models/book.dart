class Book {
  final String title;
  final String author;
  final String? imageUrl;
  final String? localImagePath;
  final String category; // 카테고리 필드 추가

  Book({
    required this.title,
    required this.author,
    this.imageUrl,
    this.localImagePath,
    this.category = '일반', // 기본값 설정
  });

  @override
  String toString() {
    return 'Book{title: $title, author: $author, category: $category, imageUrl: $imageUrl}';
  }
}