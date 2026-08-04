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
        SectionHeader(title: 'Performance', subtitle: performance.period.label),
        const SizedBox(height: 12),
        if (performance.bookingTrend.isNotEmpty) ...[
          Text(
            'Bookings',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(
              height: 180,
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: SizedBox(
              height: 180,
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

class _BookingBarChart extends StatefulWidget {
  const _BookingBarChart({required this.trend, this.isMonthly = false});

  final List<OwnerDashboardTrendPoint> trend;
  final bool isMonthly;

  @override
  State<_BookingBarChart> createState() => _BookingBarChartState();
}

class _BookingBarChartState extends State<_BookingBarChart> {
  int? _touchedGroup;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final trend = widget.trend;
    final maxY = trend
        .map((e) => e.count)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final top = maxY == 0 ? 4.0 : (maxY * 1.2).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: top,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: top / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.glassBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                    _shortDate(trend[index].date, isMonthly: widget.isMonthly),
                    style: TextStyle(fontSize: 9, color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchExtraThreshold: const EdgeInsets.all(12),
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent && event is! FlPanDownEvent) return;
            final spot = response?.spot;
            if (spot == null) return;
            final index = spot.touchedBarGroupIndex;
            setState(() {
              _touchedGroup = _touchedGroup == index ? null : index;
            });
          },
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            direction: TooltipDirection.top,
            tooltipMargin: 4,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            getTooltipColor: (_) => colors.surfaceElevated,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = _shortDate(
                trend[groupIndex].date,
                isMonthly: widget.isMonthly,
                verbose: true,
              );
              return BarTooltipItem(
                '$label · ${rod.toY.toInt()}',
                TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < trend.length; i++)
            BarChartGroupData(
              x: i,
              showingTooltipIndicators: _touchedGroup == i ? const [0] : const [],
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

  String _shortDate(
    String date, {
    bool isMonthly = false,
    bool verbose = false,
  }) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.length >= 5 ? date.substring(5) : date;
    if (isMonthly) return DateFormat('MMM').format(parsed);
    if (verbose) return DateFormat('E d').format(parsed);
    return DateFormat('E').format(parsed).substring(0, 1);
  }
}

class _RevenueLineChart extends StatefulWidget {
  const _RevenueLineChart({
    required this.trend,
    required this.currency,
    this.isMonthly = false,
  });

  final List<OwnerDashboardRevenueTrendPoint> trend;
  final String currency;
  final bool isMonthly;

  @override
  State<_RevenueLineChart> createState() => _RevenueLineChartState();
}

class _RevenueLineChartState extends State<_RevenueLineChart> {
  int? _touchedSpot;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final trend = widget.trend;
    final maxY = trend
        .map((e) => e.amount)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxY == 0 ? 100.0 : maxY * 1.2;

    final spots = [
      for (var i = 0; i < trend.length; i++)
        FlSpot(i.toDouble(), trend[i].amount),
    ];

    final lineBar = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: context.appColors.accent,
      barWidth: 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 3,
          color: context.appColors.accent,
          strokeWidth: 1,
          strokeColor: colors.surface,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: context.appColors.accent.withValues(alpha: 0.12),
      ),
    );

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: top,
        showingTooltipIndicators: _touchedSpot == null ||
                _touchedSpot! < 0 ||
                _touchedSpot! >= spots.length
            ? const []
            : [
                ShowingTooltipIndicators([
                  LineBarSpot(lineBar, 0, spots[_touchedSpot!]),
                ]),
              ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: top / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.glassBorder, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, _) {
                if (value != value.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                return Text(
                  formatMoney(value, currency: widget.currency),
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
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortDate(trend[index].date, isMonthly: widget.isMonthly),
                    style: TextStyle(fontSize: 9, color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: false,
          touchSpotThreshold: 28,
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent && event is! FlPanDownEvent) return;
            final touched = response?.lineBarSpots;
            if (touched == null || touched.isEmpty) return;
            final index = touched.first.spotIndex;
            setState(() {
              _touchedSpot = _touchedSpot == index ? null : index;
            });
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipMargin: 4,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            getTooltipColor: (_) => colors.surfaceElevated,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.spotIndex;
                final label = index >= 0 && index < trend.length
                    ? _shortDate(
                        trend[index].date,
                        isMonthly: widget.isMonthly,
                        verbose: true,
                      )
                    : '';
                final money = formatMoney(spot.y, currency: widget.currency);
                return LineTooltipItem(
                  label.isEmpty ? money : '$label · $money',
                  TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [lineBar],
      ),
    );
  }

  String _shortDate(
    String date, {
    bool isMonthly = false,
    bool verbose = false,
  }) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.length >= 5 ? date.substring(5) : date;
    if (isMonthly) return DateFormat('MMM').format(parsed);
    if (verbose) return DateFormat('E d').format(parsed);
    return DateFormat('E').format(parsed).substring(0, 1);
  }
}
