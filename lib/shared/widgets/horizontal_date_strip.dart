import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:saloon_booking/core/theme/app_animations.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';

class HorizontalDateStrip extends StatefulWidget {
  const HorizontalDateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.onMoreDates,
    this.dayCount = 14,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onMoreDates;
  final int dayCount;

  @override
  State<HorizontalDateStrip> createState() => _HorizontalDateStripState();
}

class _HorizontalDateStripState extends State<HorizontalDateStrip> {
  late final ScrollController _scrollController;
  static const double _chipWidth = 60;
  static const double _chipGap = 8;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant HorizontalDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.dayCount != widget.dayCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  List<DateTime> get _dates {
    final today = _today;
    return List.generate(
      widget.dayCount,
      (i) => DateTime(today.year, today.month, today.day + i),
    );
  }

  DateTime? get _selectedDay {
    final selected = widget.selectedDate;
    if (selected == null) return null;
    return DateTime(selected.year, selected.month, selected.day);
  }

  bool _isInStrip(DateTime day) {
    final dates = _dates;
    return dates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final selected = _selectedDay;
    if (selected == null) return;

    final dates = _dates;
    final index = dates.indexWhere(
      (d) =>
          d.year == selected.year &&
          d.month == selected.month &&
          d.day == selected.day,
    );
    if (index < 0) return;

    final target = index * (_chipWidth + _chipGap);
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target.clamp(0.0, max),
      duration: kPageDuration,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dates = _dates;
    final selected = _selectedDay;
    final monthAnchor = selected ?? dates.first;
    final monthLabel = DateFormat.yMMMM().format(monthAnchor);
    final selectedOutsideStrip =
        selected != null && !_isInStrip(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                monthLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (selectedOutsideStrip)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: colors.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  DateFormat.MMMd().format(selected),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: dates.length + (widget.onMoreDates != null ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: _chipGap),
            itemBuilder: (context, index) {
              if (widget.onMoreDates != null && index == dates.length) {
                return _MoreDatesChip(onTap: widget.onMoreDates!);
              }

              final date = dates[index];
              final isSelected =
                  selected != null &&
                  date.year == selected.year &&
                  date.month == selected.month &&
                  date.day == selected.day;
              final isToday =
                  date.year == _today.year &&
                  date.month == _today.month &&
                  date.day == _today.day;

              return _DateChip(
                dayLabel: isToday ? 'Today' : DateFormat.E().format(date),
                dateLabel: DateFormat.d().format(date),
                selected: isSelected,
                isToday: isToday,
                colors: colors,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onDateSelected(date);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.dayLabel,
    required this.dateLabel,
    required this.selected,
    required this.isToday,
    required this.colors,
    required this.onTap,
  });

  final String dayLabel;
  final String dateLabel;
  final bool selected;
  final bool isToday;
  final AppThemeExtension colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: kMicroDuration,
          curve: Curves.easeOutCubic,
          width: _HorizontalDateStripState._chipWidth,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? colors.accentGradient : null,
            color: selected ? null : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.55)
                  : isToday
                  ? colors.accent.withValues(alpha: 0.35)
                  : colors.glassBorder.withValues(alpha: 0.55),
              width: selected || isToday ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: selected
                      ? colors.onAccent.withValues(alpha: 0.9)
                      : colors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: selected ? colors.onAccent : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreDatesChip extends StatelessWidget {
  const _MoreDatesChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: _HorizontalDateStripState._chipWidth,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.accent.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: colors.accent,
              ),
              const SizedBox(height: 6),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: colors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
