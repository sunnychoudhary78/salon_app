import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saloon_booking/core/constants/salon_service_names.dart';
import 'package:saloon_booking/core/theme/app_theme_extension.dart';
import 'package:saloon_booking/shared/widgets/glass_bottom_sheet.dart';
import 'package:saloon_booking/shared/widgets/premium_text_field.dart';
import 'package:saloon_booking/shared/widgets/service_artwork.dart';

const _kHairNames = {
  'Haircut',
  'Hair Color',
  'Hair Wash',
  'Hair Styling',
  'Hair Spa',
  'Hair Highlights',
  'Hair Smoothening',
  'Hair Straightening',
  'Hair Fall Treatment',
  'Keratin Treatment',
  'Scalp Treatment',
  'Dandruff Treatment',
  'Hair Extensions',
  'Hair Botox',
};

const _kFaceNames = {
  'Facial',
  'Cleanup',
  'Hydra Facial',
  'Face Scrub',
  'Face Massage',
  'De-Tan Treatment',
  'Eyebrow Grooming',
  'Threading',
  'Waxing',
};

const _kSpaNames = {'Head Massage', 'Body Massage', 'Foot Spa'};

const _kNailNames = {'Manicure', 'Pedicure', 'Nail Art', 'Nail Extensions'};

const _kBeardNames = {'Beard Trim', 'Beard Color', 'Beard Styling', 'Shaving'};

const _kPackageNames = {
  'Groom Package',
  'Groom Makeup',
  'Signature Grooming Package',
  'Bridal Makeup',
  'Bridal Beauty Package',
  'Pre Bridal Package',
  'Party Makeup',
};

const _kGroupOrder = <(String, Set<String>)>[
  ('Hair', _kHairNames),
  ('Face & skin', _kFaceNames),
  ('Spa', _kSpaNames),
  ('Nails', _kNailNames),
  ('Beard & shave', _kBeardNames),
  ('Packages', _kPackageNames),
];

Future<String?> showServiceCatalogPicker({
  required BuildContext context,
  required List<String> catalogNames,
  required String selectedName,
  required AudienceMode audience,
}) {
  return showGlassBottomSheet<String>(
    context: context,
    builder: (ctx) => _ServiceCatalogPickerSheet(
      catalogNames: catalogNames,
      selectedName: selectedName,
      audience: audience,
    ),
  );
}

class _ServiceCatalogPickerSheet extends StatefulWidget {
  const _ServiceCatalogPickerSheet({
    required this.catalogNames,
    required this.selectedName,
    required this.audience,
  });

  final List<String> catalogNames;
  final String selectedName;
  final AudienceMode audience;

  @override
  State<_ServiceCatalogPickerSheet> createState() =>
      _ServiceCatalogPickerSheetState();
}

class _ServiceCatalogPickerSheetState extends State<_ServiceCatalogPickerSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _catalog {
    final names = <String>[
      if (widget.selectedName != kCustomSalonServiceName &&
          !widget.catalogNames.contains(widget.selectedName))
        widget.selectedName,
      ...widget.catalogNames,
    ];
    return names;
  }

  bool _matchesQuery(String name, String query) {
    if (query.isEmpty) return true;
    return name.toLowerCase().contains(query);
  }

  List<(String, List<String>)> _groupedMatches(String query) {
    final remaining = _catalog.toSet();
    final groups = <(String, List<String>)>[];

    for (final (label, members) in _kGroupOrder) {
      final items = [
        for (final name in _catalog)
          if (members.contains(name) && _matchesQuery(name, query)) name,
      ];
      remaining.removeAll(members);
      if (items.isNotEmpty) groups.add((label, items));
    }

    final other = [
      for (final name in _catalog)
        if (remaining.contains(name) && _matchesQuery(name, query)) name,
    ];
    if (other.isNotEmpty) groups.add(('Other', other));
    return groups;
  }

  void _select(String name) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final query = _searchController.text.trim().toLowerCase();
    final groups = _groupedMatches(query);
    final showCustom =
        query.isEmpty || _matchesQuery(kCustomSalonServiceName, query);
    final sheetHeight = (media.size.height * 0.78).clamp(
      320.0,
      media.size.height - keyboard,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose a service',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search the catalog or add a custom offering',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  PremiumTextField(
                    controller: _searchController,
                    label: 'Search',
                    hint: 'Haircut, facial, beard…',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colors.textMuted,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: groups.isEmpty && !showCustom
                  ? Center(
                      child: Text(
                        'No matching services',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        4,
                        12,
                        16 + media.padding.bottom,
                      ),
                      children: [
                        for (final (label, names) in groups) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                            child: Text(
                              label.toUpperCase(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                          ),
                          for (final name in names)
                            _CatalogTile(
                              name: name,
                              selected: name == widget.selectedName,
                              audience: widget.audience,
                              onTap: () => _select(name),
                            ),
                        ],
                        if (showCustom) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                            child: Text(
                              'CUSTOM',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                          ),
                          _CatalogTile(
                            name: kCustomSalonServiceName,
                            selected:
                                widget.selectedName == kCustomSalonServiceName,
                            audience: widget.audience,
                            onTap: () => _select(kCustomSalonServiceName),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.name,
    required this.selected,
    required this.audience,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final AudienceMode audience;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isCustom = name == kCustomSalonServiceName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? colors.accentSoft : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.accent : colors.glassBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                ServiceArtwork(
                  serviceName: isCustom ? '' : name,
                  audience: audience,
                  size: 44,
                  padding: const EdgeInsets.all(6),
                  borderRadius: 12,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: colors.accent)
                else
                  Icon(Icons.chevron_right_rounded, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
