import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/features/customer/data/providers/salon_browse_filters_provider.dart';
import 'package:saloon_booking/features/customer/presentation/widgets/audience_mode_toggle.dart';

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
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hello, ${widget.firstName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const AudienceModeToggle(),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SearchField(
                controller: widget.searchController,
                hasText: hasText,
                onChanged: widget.onSearchChanged,
                onClear: _clearSearch,
              ),
            ),
            const SizedBox(width: 10),
            _FilterButton(
              hasActiveFilters: hasActiveFilters,
              onTap: widget.onFilterTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
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
    final colors = context.appColors;

    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search salons…',
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          filled: true,
          fillColor: colors.surface,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusControl),
            borderSide: BorderSide(color: colors.glassBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusControl),
            borderSide: BorderSide(color: colors.glassBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusControl),
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colors.textMuted,
            size: 20,
          ),
          suffixIcon: hasText
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.hasActiveFilters, required this.onTap});

  final bool hasActiveFilters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 22,
                color: hasActiveFilters ? colors.primary : colors.textSecondary,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surface, width: 1.5),
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
