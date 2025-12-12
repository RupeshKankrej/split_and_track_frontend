import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/api_client.dart';

class AnalysisScreen extends StatefulWidget {
  final String baseUrl;
  final int userId;

  const AnalysisScreen({
    super.key,
    required this.baseUrl,
    required this.userId,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  List<dynamic> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    try {
      final response = await ApiClient.create(
        widget.baseUrl,
      ).get('${widget.baseUrl}/expenses/analysis/${widget.userId}');
      if (mounted) {
        setState(() {
          _data = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Spend Analysis")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text("No data available", style: theme.textTheme.titleMedium),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // CHART CARD
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            "Expense Breakdown",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 250,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 50,
                                sections: _generateSections(
                                  theme.brightness == Brightness.dark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // LEGEND LIST
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _data.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _data[index];
                      final double value =
                          (item['totalAmount'] as num?)?.toDouble() ?? 0.0;

                      return ListTile(
                        leading: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getColor(
                              index,
                              theme.brightness == Brightness.dark,
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(item['category'] ?? "Uncategorized"),
                        trailing: Text(
                          "₹${value.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  List<PieChartSectionData> _generateSections(bool isDark) {
    return List.generate(_data.length, (index) {
      final item = _data[index];
      final double value = (item['totalAmount'] as num?)?.toDouble() ?? 0.0;
      if (value <= 0) return null;

      return PieChartSectionData(
        color: _getColor(index, isDark),
        value: value,
        title: '${value.toInt()}',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.black : Colors.white,
        ),
      );
    }).whereType<PieChartSectionData>().toList();
  }

  Color _getColor(int index, bool isDark) {
    // Modern Palette
    const lightColors = [
      Color(0xFF4285F4),
      Color(0xFFDB4437),
      Color(0xFFF4B400),
      Color(0xFF0F9D58),
      Color(0xFFAB47BC),
    ];
    const darkColors = [
      Color(0xFF8AB4F8),
      Color(0xFFF28B82),
      Color(0xFFFDD663),
      Color(0xFF81C995),
      Color(0xFFD6B0E9),
    ];

    final palette = isDark ? darkColors : lightColors;
    return palette[index % palette.length];
  }
}
