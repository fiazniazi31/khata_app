import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/category.dart';

class ExpenseDonutChart extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final double totalAmount;
  final String currency;

  const ExpenseDonutChart({
    super.key,
    required this.categories,
    required this.totalAmount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (totalAmount <= 0) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(
              "No expenses recorded yet",
              style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // The Donut Canvas Chart
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: _DonutChartPainter(
              categories: categories,
              totalAmount: totalAmount,
              centerColor: theme.scaffoldBackgroundColor,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "TOTAL SPENT",
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white38 : Colors.black38,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        "$currency${totalAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Mini legend list on the side
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: categories
                .where((c) => c.totalAmount > 0)
                .map((c) {
                  final pct = (c.totalAmount / totalAmount) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.title,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${pct.toStringAsFixed(0)}%",
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ExpenseCategory> categories;
  final double totalAmount;
  final Color centerColor;

  _DonutChartPainter({
    required this.categories,
    required this.totalAmount,
    required this.centerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final double width = size.width;
    final double height = size.height;
    final center = Offset(width / 2, height / 2);
    final radius = min(width, height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2; // start from top (12 o'clock)

    for (var cat in categories) {
      if (cat.totalAmount <= 0) continue;

      final double sweepAngle = (cat.totalAmount / totalAmount) * 2 * pi;

      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }

    // Cut a inner circle to create a Donut
    final innerPaint = Paint()
      ..color = centerColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius * 0.70, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.categories != categories || oldDelegate.totalAmount != totalAmount || oldDelegate.centerColor != centerColor;
  }
}
