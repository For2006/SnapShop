import 'package:flutter/material.dart';
import '../../core/mock_data.dart';
import 'suggestion_card.dart';

class SuggestionList extends StatelessWidget {
  final List<MockSuggestion> suggestions;
  final Function(MockSuggestion) onTap;

  const SuggestionList({
    super.key,
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return SuggestionCard(
            suggestion: suggestion,
            onTap: () => onTap(suggestion),
          );
        },
      ),
    );
  }
}
