import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/core/utils/currency_utils.dart';
import 'package:saloon_booking/features/owner/data/models/owner_dashboard_v2_model.dart';
import 'package:saloon_booking/shared/widgets/glass_card.dart';
import 'package:saloon_booking/shared/widgets/section_header.dart';

class OwnerPerformanceCharts extends StatelessWidget {
  const OwnerPerformanceCharts({
    super.key,
    required this.performance,
    required this.currency,
  });

  final OwnerDashboardPerformance performance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (performance.bookingTrend.isEmpty && performance.revenueTrend.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Performance',
          subtitle: performance.period.label,
        ),
        const SizedBox(height: 12),
        if (performance.bookingTrend.isNotEmpty) ...[
          Text(
            'Bookings',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(
              height: 160,
              child: _BookingBarChart(
                trend: performance.bookingTrend,
                isMonthly: performance.period.isMonthly,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (performance.revenueTrend.isNotEmpty) ...[
          Text(
            'Revenue',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(
              height: 160,
              child: _RevenueLineChart(
                trend: performance.revenueTrend,
                currency: currency,
                isMonthly: performance.period.isMonthly,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BookingBarChart extends StatelessWidget {
  const _BookingBarChart({
    required this.trend,
    this.isMonthly = false,
  });

  final List<OwnerDashboardTrendPoint> trend;
  final bool isMonthly;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxY = trend.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b);
    final top = maxY == 0 ? 4.0 : (maxY * 1.2).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: top,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: top / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.glassBorder,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: colors.textMuted),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortDate(trend[index].date, isMonthly: isMonthly),
                    style: TextStyle(fontSize: 9, color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < trend.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: trend[i].count.toDouble(),
                  color: AppColors.primary,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _shortDate(String date, {bool isMonthly = false}) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.length >= 5 ? date.substring(5) : date;
    if (isMonthly) return DateFormat('MMM').format(parsed);
    return DateFormat('E').format(parsed).substring(0, 1);
  }
}

class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({
    required this.trend,
    required this.currency,
    this.isMonthly = false,
  });

  final List<OwnerDashboardRevenueTrendPoint> trend;
  final String currency;
  final bool isMonthly;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxY = trend
        .map((e) => e.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxY == 0 ? 100.0 : maxY * 1.2;

    final spots = [
      for (var i = 0; i < trend.length; i++)
        FlSpot(i.toDouble(), trend[i].amount),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: top,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: top / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colors.glassBorder,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return Text(
                  formatMoney(value, currency: currency),
                  style: TextStyle(fontSize: 9, color: colors.textMuted),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index < 0 || index >= trend.length) {
                  return const SizedBox.shrink();
                }
                final parsed = DateTime.tryParse(trend[index].date);
                final label = parsed != null
                    ? (isMonthly
                        ? DateFormat('MMM').format(parsed)
                        : DateFormat('E').format(parsed).substring(0, 1))
                    : trend[index].date;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 9, color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.accent,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.accent,
                strokeWidth: 1,
                strokeColor: colors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
