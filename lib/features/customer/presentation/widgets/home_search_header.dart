import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/features/customer/data/providers/salon_browse_filters_provider.dart';

class HomeSearchHeader extends ConsumerStatefulWidget {
  const HomeSearchHeader({
    super.key,
    required this.firstName,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  final String firstName;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onFilterTap;

  @override
  ConsumerState<HomeSearchHeader> createState() => _HomeSearchHeaderState();
}

class _HomeSearchHeaderState extends ConsumerState<HomeSearchHeader> {
  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _clearSearch() {
    widget.searchController.clear();
    widget.onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(salonBrowseFiltersProvider);
    final hasActiveFilters = filters.hasActiveFilters;
    final hasText = widget.searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, ${widget.firstName}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SearchPill(
                controller: widget.searchController,
                hasText: hasText,
                onChanged: widget.onSearchChanged,
                onClear: _clearSearch,
              ),
            ),
            const SizedBox(width: 10),
            _NeumorphicFilterButton(
              hasActiveFilters: hasActiveFilters,
              onTap: widget.onFilterTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.surfaceElevated.withValues(alpha: 0.55),
                      AppColors.surface.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
              decoration: InputDecoration(
                hintText: 'Search salons…',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                contentPadding: const EdgeInsets.fromLTRB(18, 15, 8, 15),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                suffixIcon: hasText
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                        onPressed: onClear,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Icon(
                          Icons.search_rounded,
                          color: AppColors.textMuted.withValues(alpha: 0.85),
                          size: 20,
                        ),
                      ),
                suffixIconConstraints: hasText
                    ? null
                    : const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeumorphicFilterButton extends StatelessWidget {
  const _NeumorphicFilterButton({
    required this.hasActiveFilters,
    required this.onTap,
  });

  final bool hasActiveFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceElevated.withValues(alpha: 0.85),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.06),
                offset: const Offset(-2, -2),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                offset: const Offset(2, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 22,
                color: hasActiveFilters
                    ? AppColors.accent
                    : AppColors.textSecondary,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundDark,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
