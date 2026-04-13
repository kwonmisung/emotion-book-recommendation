import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';
import '../models/book.dart';

class CsvLoader {
  static Future<List<Book>> loadBooksFromAws(String url) async {
    try {
      print('=== CSV 로드 시작 ===');
      print('URL: $url');

      final response = await http.get(Uri.parse(url));
      print('응답 코드: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('HTTP 오류: ${response.statusCode}');
        return [];
      }

      String csvContent = utf8.decode(response.bodyBytes);
      print('파일 크기: ${csvContent.length}자');

      // 줄바꿈 문자 타입 확인
      int crlfCount = '\r\n'.allMatches(csvContent).length;
      int lfCount = '\n'.allMatches(csvContent).length - crlfCount;
      int crCount = '\r'.allMatches(csvContent).length - crlfCount;
      print('줄바꿈 문자 분석: CRLF(\\r\\n): $crlfCount, LF(\\n): $lfCount, CR(\\r): $crCount');

      // 줄바꿈 문자 정규화 (Windows/Mac/Linux 호환성)
      csvContent = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

      // 처음 3줄 원본 출력 (따옴표 확인용)
      List<String> lines = csvContent.split('\n');
      print('총 줄 수: ${lines.length}');
      print('=== 원본 파일 내용 (처음 3줄) ===');
      for (int i = 0; i < 3 && i < lines.length; i++) {
        print('줄 ${i+1}: ${lines[i]}');
      }
      print('==================');

      // CSV 파싱 옵션 개선
      List<List<dynamic>> csvData;
      try {
        csvData = const CsvToListConverter(
          fieldDelimiter: ',',           // 쉼표로 구분
          textDelimiter: '"',            // 큰따옴표로 텍스트 구분
          textEndDelimiter: '"',         // 큰따옴표로 텍스트 끝
          eol: '\n',                     // 줄바꿈 문자 (정규화됨)
          shouldParseNumbers: false,      // 숫자 자동 변환 비활성화
        ).convert(csvContent);
        print('✅ CSV 파싱 성공: ${csvData.length}행');
      } catch (e) {
        print('❌ 표준 CSV 파싱 실패: $e');
        print('수동 파싱 시도...');
        return _manualParseWithQuotes(csvContent);
      }

      if (csvData.length < 2) {
        print('데이터가 부족합니다');
        return [];
      }

      // 헤더 확인
      print('헤더: ${csvData[0]}');

      List<Book> books = [];

      // 각 행 처리
      for (int i = 1; i < csvData.length; i++) {
        var row = csvData[i];
        print('행 $i (원본): $row');

        if (row.length >= 2) {
          String rawTitle = row[0]?.toString() ?? '';
          String rawAuthor = row[1]?.toString() ?? '';
          String rawImageUrl = row.length > 2 ? (row[2]?.toString() ?? '') : '';
          String rawLocalPath = row.length > 3 ? (row[3]?.toString() ?? '') : '';
          String rawCategory= row.length > 4 ? (row[4]?.toString() ?? '') : '';

          // 따옴표 제거 및 정리
          String title = _cleanText(rawTitle);
          String author = _cleanText(rawAuthor);
          String imageUrl = _cleanText(rawImageUrl);
          String localPath = _cleanText(rawLocalPath);
          String category = _cleanText(rawCategory);

          print('  정리된 데이터: "$title" | "$author" | "$imageUrl" | "$localPath" |"$category"');

          if (title.isNotEmpty && author.isNotEmpty) {
            books.add(Book(
              title: title,
              author: author,
              imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
              localImagePath: localPath.isNotEmpty ? localPath : null,
              category: category,
            ));
            print('  -> ✅ 추가됨');
          } else {
            print('  -> ❌ 제목 또는 저자가 비어있음');
          }
        }
      }

      print('=== 최종 결과 ===');
      print('로드된 책 수: ${books.length}');
      for (int i = 0; i < books.length && i < 5; i++) {
        print('책 ${i+1}: "${books[i].title}" by "${books[i].author}"');
      }
      print('===============');

      return books;

    } catch (e, stackTrace) {
      print('❌ 오류 발생: $e');
      print('스택 트레이스: $stackTrace');
      return [];
    }
  }

  // 텍스트 정리 (따옴표, 공백 등 제거)
  static String _cleanText(String input) {
    if (input.isEmpty) return input;

    return input
        .trim()                          // 앞뒤 공백 제거
        .replaceAll(RegExp(r'^"'), '')   // 시작 따옴표 제거
        .replaceAll(RegExp(r'"$'), '')   // 끝 따옴표 제거
        .replaceAll('""', '"')           // 이중 따옴표 처리
        .trim();                         // 다시 공백 제거
  }

  // 수동 파싱 (따옴표 처리 포함)
  static Future<List<Book>> _manualParseWithQuotes(String csvContent) async {
    print('🔧 수동 파싱 시작 (따옴표 처리)');

    List<String> lines = csvContent.split('\n');
    List<Book> books = [];

    // 첫 번째 줄은 헤더로 건너뛰기
    for (int i = 1; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;

      print('처리할 라인: $line');

      // 수동으로 CSV 파싱 (따옴표 고려)
      List<String> fields = _parseCSVLine(line);
      print('파싱된 필드들: $fields');

      if (fields.length >= 2) {
        String title = _cleanText(fields[0]);
        String author = _cleanText(fields[1]);

        if (title.isNotEmpty && author.isNotEmpty) {
          books.add(Book(title: title, author: author));
          print('수동 파싱으로 책 추가: "$title" - "$author"');
        }
      }
    }

    print('수동 파싱 결과: ${books.length}개의 책');
    return books;
  }

  // CSV 라인을 수동으로 파싱 (따옴표 처리)
  static List<String> _parseCSVLine(String line) {
    List<String> fields = [];
    String currentField = '';
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == '"') {
        // 따옴표 처리
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // 이중 따옴표 ("") -> 하나의 따옴표로 처리
          currentField += '"';
          i++; // 다음 따옴표 건너뛰기
        } else {
          // 따옴표 시작/끝
          insideQuotes = !insideQuotes;
        }
      } else if (char == ',' && !insideQuotes) {
        // 쉼표로 필드 구분 (따옴표 안이 아닐 때만)
        fields.add(currentField);
        currentField = '';
      } else {
        currentField += char;
      }
    }

    // 마지막 필드 추가
    fields.add(currentField);

    return fields;
  }
}