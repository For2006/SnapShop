import 'package:flutter/material.dart';
import '../../core/mock_data.dart';
import 'suggestion_card.dart';

class SuggestionList extends StatefulWidget {
  final List<MockSuggestion> suggestions;
  final Function(MockSuggestion?) onTap;
  final bool multiSelect;
  final Set<String> selectedIds;

  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.onTap,
    this.multiSelect = false,
    this.selectedIds = const {},
  });

  @override
  State<SuggestionList> createState() => _SuggestionListState();
}

class _SuggestionListState extends State<SuggestionList> {
  String? _selectedCardId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final suggestion = widget.suggestions[index];
          final isSelected = widget.multiSelect
              ? widget.selectedIds.contains(suggestion.id)
              : _selectedCardId == suggestion.id;
          return SuggestionCard(
            suggestion: suggestion,
            isSelected: isSelected,
            onTap: () {
              if (widget.multiSelect) {
                widget.onTap(suggestion);
              } else {
                setState(() {
                  if (_selectedCardId == suggestion.id) {
                    _selectedCardId = null;
                    widget.onTap(null);
                  } else {
                    _selectedCardId = suggestion.id;
                    widget.onTap(suggestion);
                  }
                });
              }
            },
          );
        },
      ),
    );
  }
}
