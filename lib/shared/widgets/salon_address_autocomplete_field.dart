import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saloon_booking/core/theme/app_colors.dart';
import 'package:saloon_booking/core/theme/app_decorations.dart';
import 'package:saloon_booking/features/owner/data/models/place_suggestion.dart';
import 'package:saloon_booking/features/owner/data/services/places_search_service.dart';

class SalonAddressAutocompleteField extends ConsumerStatefulWidget {
  const SalonAddressAutocompleteField({
    super.key,
    required this.onPlaceSelected,
  });

  final ValueChanged<PlaceSuggestion> onPlaceSelected;

  @override
  ConsumerState<SalonAddressAutocompleteField> createState() =>
      _SalonAddressAutocompleteFieldState();
}

class _SalonAddressAutocompleteFieldState
    extends ConsumerState<SalonAddressAutocompleteField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  bool _suppressSearch = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() => _suggestions = []);
    }
  }

  void _onQueryChanged(String value) {
    if (_suppressSearch) {
      _suppressSearch = false;
      return;
    }

    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(value.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results =
          await ref.read(placesSearchServiceProvider).searchPlaces(query);
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _suggestions = results;
        _loading = false;
        if (results.isEmpty) _error = 'No places found';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _suggestions = [];
        _error = 'Could not load suggestions';
      });
    }
  }

  void _selectPlace(PlaceSuggestion place) {
    _suppressSearch = true;
    _controller.text = place.label;
    setState(() {
      _suggestions = [];
      _error = null;
    });
    _focusNode.unfocus();
    widget.onPlaceSelected(place);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          style: const TextStyle(color: Colors.white),
          decoration: AppDecorations.inputDecoration(
            label: 'Search salon address *',
            hint: 'Start typing area, street, or landmark',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _suggestions = [];
                            _error = null;
                          });
                        },
                      )
                    : null,
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: AppDecorations.glass(radius: 14),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppColors.glassBorder.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final place = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.accent.withValues(alpha: 0.9),
                      size: 20,
                    ),
                    title: Text(
                      place.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => _selectPlace(place),
                  );
                },
              ),
            ),
          ),
        ],
        if (_error != null && _suggestions.isEmpty && !_loading) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Pick a suggestion to auto-fill address, city, state, and map pin.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
