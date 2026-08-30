import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/transaction.dart';

class AnalyticsChart extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;

  const AnalyticsChart({
    super.key,
    required this.transactions,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart_rounded, size: 40, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 8),
            const Text(
              "No transaction history to chart",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Sort chronologically (oldest first) to plot running balance
    final chronological = List<TransactionModel>.from(transactions).reversed.toList();
    
    List<double> runningBalances = [];
    double currentBalance = 0.0;
    for (var tx in chronological) {
      if (tx.type == 'give') {
        currentBalance += tx.price;
      } else {
        currentBalance -= tx.price;
      }
      runningBalances.add(currentBalance);
    }

    // Add initial zero point if we only have one transaction
    if (runningBalances.length == 1) {
      runningBalances.insert(0, 0.0);
    }

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Running Ledger Trend",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Text(
                "Final: $currency${currentBalance.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: currentBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _LedgerChartPainter(
                    balances: runningBalances,
                    primaryColor: currentBalance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerChartPainter extends CustomPainter {
  final List<double> balances;
  final Color primaryColor;

  _LedgerChartPainter({required this.balances, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (balances.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    // Find min/max values
    double maxVal = balances.reduce(max);
    double minVal = balances.reduce(min);
    
    // Pad values so line doesn't touch edges
    double range = maxVal - minVal;
    if (range == 0) range = 100;
    maxVal += range * 0.15;
    minVal -= range * 0.15;
    range = maxVal - minVal;

    final double stepX = width / (balances.length - 1);

    // Draw Grid Lines (horizontal)
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.08)
      ..strokeWidth = 1;

    for (int i = 0; i <= 3; i++) {
      final double y = height - (i * height / 3);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Generate Points
    List<Offset> points = [];
    for (int i = 0; i < balances.length; i++) {
      final double x = i * stepX;
      // Normalise balance into [0, 1] range relative to canvas heights
      final double pctY = (balances[i] - minVal) / range;
      // Invert Y coordinate because canvas 0 is top
      final double y = height - (pctY * height);
      points.add(Offset(x, y));
    }

    // Generate Cubic Path (Bezier Curve)
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final double controlX1 = points[i].dx + (points[i + 1].dx - points[i].dx) / 2;
      final double controlY1 = points[i].dy;
      final double controlX2 = points[i].dx + (points[i + 1].dx - points[i].dx) / 2;
      final double controlY2 = points[i + 1].dy;

      path.cubicTo(
        controlX1,
        controlY1,
        controlX2,
        controlY2,
        points[i + 1].dx,
        points[i + 1].dy,
      );
    }

    // Create a path for the gradient fill below the line
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    // Paint the Fill Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [primaryColor.withOpacity(0.25), primaryColor.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Paint the Stroke Line
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawPath(path, linePaint);

    // Draw End Circle Point
    final circlePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final endPoint = points.last;
    canvas.drawCircle(endPoint, 4.5, circlePaint);
    canvas.drawCircle(endPoint, 4.5, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _LedgerChartPainter oldDelegate) {
    return oldDelegate.balances != balances || oldDelegate.primaryColor != primaryColor;
  }
}
