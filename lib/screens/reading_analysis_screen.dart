import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../Services/reading_analysis_service.dart';
import '../models/reading_analysis.dart';

class ReadingAnalysisScreen extends StatefulWidget {
  final String userId;
  final ReadingAnalysis? initialData;

  const ReadingAnalysisScreen({
    Key? key,
    required this.userId,
    this.initialData,
  }) : super(key: key);

  @override
  State<ReadingAnalysisScreen> createState() => _ReadingAnalysisScreenState();
}

class _ReadingAnalysisScreenState extends State<ReadingAnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  ReadingAnalysis? analysisData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 이미 데이터가 있으면 사용, 없으면 로드
    if (widget.initialData != null) {
      analysisData = widget.initialData;
      isLoading = false;
      _animationController.forward();
    } else {
      _loadAnalysisData();
    }
  }

  Future<void> _loadAnalysisData() async {
    try {
      final data = await AuthenticatedReadingService.getCurrentUserAnalysis();
      setState(() {
        analysisData = data;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // 에러 처리
      print('Analysis loading error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : analysisData == null
          ? _buildErrorView()
          : _buildAnalysisView(),
    );
  }

  Widget _buildAnalysisView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewCard(),
                const SizedBox(height: 20),
                _buildFavoriteAuthorsCard(),
                const SizedBox(height: 20),
                _buildReadingPatternsCard(),
                const SizedBox(height: 20),
                _buildRecommendationsCard(),
                const SizedBox(height: 20),
                _buildImprovementTipsCard(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2D3436),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          '📚 독서 분석 리포트',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF2D3436),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  '${analysisData!.analysisPeriod}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '총 ${analysisData!.totalBooks}권',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: Color(0xFF6C5CE7), size: 28),
              SizedBox(width: 12),
              Text(
                '독서 인사이트',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoTile('📈 독서 빈도', analysisData!.analysis.readingFrequency),
          _buildInfoTile('🎭 주요 테마', analysisData!.analysis.readingThemes),
          _buildInfoTile('📖 독서 스타일', analysisData!.analysis.contentAnalysis),
          _buildInfoTile('⏰ 시간 패턴', analysisData!.analysis.timePattern),
        ],
      ),
    );
  }

  Widget _buildFavoriteAuthorsCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: Color(0xFFE17055), size: 28),
              SizedBox(width: 12),
              Text(
                '선호 작가',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildAuthorChart(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysisData!.analysis.favoriteAuthors.map((author) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF6C5CE7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFF6C5CE7).withOpacity(0.3)),
                ),
                child: Text(
                  author,
                  style: TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingPatternsCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Color(0xFF00B894), size: 28),
              SizedBox(width: 12),
              Text(
                '독서 패턴',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            child: _buildReadingPatternChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.recommend, color: Color(0xFFFFD93D), size: 28),
              SizedBox(width: 12),
              Text(
                '추천 도서',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analysisData!.analysis.recommendations.asMap().entries.map((entry) {
            int index = entry.key;
            String book = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFD93D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFFD93D).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFFFD93D),
                    radius: 16,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      book,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildImprovementTipsCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFF00CEC9), size: 28),
              SizedBox(width: 12),
              Text(
                '개선 팁',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analysisData!.analysis.improvementTips.map((tip) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF00CEC9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF00CEC9).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF00CEC9),
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInfoTile(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorChart() {
    return PieChart(
      PieChartData(
        sections: analysisData!.analysis.favoriteAuthors.asMap().entries.map((entry) {
          int index = entry.key;
          String author = entry.value;

          List<Color> colors = [
            Color(0xFF6C5CE7),
            Color(0xFFE17055),
            Color(0xFF00B894),
            Color(0xFFFFD93D),
            Color(0xFFFF7675),
          ];

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: (analysisData!.analysis.favoriteAuthors.length - index).toDouble(),
            title: author.length > 8 ? '${author.substring(0, 8)}...' : author,
            radius: 80,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReadingPatternChart() {
    // 더미 데이터로 월별 독서량 차트
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                List<String> months = ['3월', '4월', '5월', '6월', '7월', '8월', '9월'];
                if (value.toInt() >= 0 && value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  );
                }
                return Text('');
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 1),
              FlSpot(1, 3),
              FlSpot(2, 2),
              FlSpot(3, 4),
              FlSpot(4, 2),
              FlSpot(5, 3),
              FlSpot(6, 1),
            ],
            isCurved: true,
            color: Color(0xFF00B894),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: Color(0xFF00B894).withOpacity(0.3),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            '분석 데이터를 불러올 수 없습니다',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              _loadAnalysisData();
            },
            child: Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}