import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/khata_provider.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<KhataProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chartData = provider.categoryExpenseChartData;
    final monthlyCompareData = provider.monthlyIncomeVsExpenseData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Summary Overview
          _buildSummaryHeader(provider, isDark),
          const SizedBox(height: 20),

          // 1. Expense Breakdown Donut Chart
          Text(
            'Expense Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildPieChartCard(provider, chartData, isDark),
          const SizedBox(height: 24),

          // 2. Income vs. Expense Bar Chart
          Text(
            'Income vs Expense (Last 6 Months)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildBarChartCard(provider, monthlyCompareData, isDark),
          const SizedBox(height: 24),

          // 3. Cashflow Trend Line Graph
          Text(
            'Net Cashflow Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildLineChartCard(provider, monthlyCompareData, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(KhataProvider provider, bool isDark) {
    final symbol = provider.currencySymbol;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn('Monthly Income', '$symbol ${provider.totalMonthlyIncome.toStringAsFixed(0)}', Colors.greenAccent),
          Container(height: 40, width: 1, color: Colors.white24),
          _buildStatColumn('Monthly Expenses', '$symbol ${provider.totalMonthlyExpenses.toStringAsFixed(0)}', Colors.redAccent),
          Container(height: 40, width: 1, color: Colors.white24),
          _buildStatColumn('Net Savings', '$symbol ${provider.monthlyRemainingBalance.toStringAsFixed(0)}', Colors.amberAccent),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(KhataProvider provider, List<Map<String, dynamic>> chartData, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: chartData.isEmpty
            ? const SizedBox(
                height: 180,
                child: Center(child: Text("No expenses recorded for this month.")),
              )
            : Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: List.generate(chartData.length, (i) {
                            final isTouched = i == _touchedPieIndex;
                            final radius = isTouched ? 55.0 : 45.0;
                            final item = chartData[i];
                            final color = item['color'] as Color;
                            final percentage = item['percentage'] as double;
                            return PieChartSectionData(
                              color: color,
                              value: item['amount'] as double,
                              title: '${percentage.toStringAsFixed(0)}%',
                              radius: radius,
                              titleStyle: TextStyle(
                                fontSize: isTouched ? 14 : 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: chartData.map((item) {
                        final color = item['color'] as Color;
                        final title = item['title'] as String;
                        final amount = item['amount'] as double;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${provider.currencySymbol}${amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBarChartCard(KhataProvider provider, List<Map<String, dynamic>> monthlyCompareData, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _calculateMaxBarY(monthlyCompareData),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < monthlyCompareData.length) {
                        final date = monthlyCompareData[index]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            DateFormat('MMM').format(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(monthlyCompareData.length, (index) {
                final item = monthlyCompareData[index];
                final income = item['income'] as double;
                final expense = item['expense'] as double;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(toY: income, color: Colors.green, width: 10, borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(toY: expense, color: Colors.redAccent, width: 10, borderRadius: BorderRadius.circular(4)),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChartCard(KhataProvider provider, List<Map<String, dynamic>> monthlyCompareData, bool isDark) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < monthlyCompareData.length; i++) {
      final income = monthlyCompareData[i]['income'] as double;
      final expense = monthlyCompareData[i]['expense'] as double;
      spots.add(FlSpot(i.toDouble(), income - expense));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < monthlyCompareData.length) {
                        final date = monthlyCompareData[index]['date'] as DateTime;
                        return Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blueAccent.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _calculateMaxBarY(List<Map<String, dynamic>> data) {
    double max = 100;
    for (var item in data) {
      final inc = item['income'] as double;
      final exp = item['expense'] as double;
      if (inc > max) max = inc;
      if (exp > max) max = exp;
    }
    return max * 1.2;
  }
}
