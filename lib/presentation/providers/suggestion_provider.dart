import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/repurchase_suggestion.dart';
import '../../data/repositories/suggestion_repository.dart';

/// Suggestion repository provider
final suggestionRepositoryProvider = Provider<SuggestionRepository>((ref) {
  return SuggestionRepository();
});

/// Active suggestions provider
final suggestionsProvider = FutureProvider<List<RepurchaseSuggestion>>((ref) async {
  final repo = ref.watch(suggestionRepositoryProvider);

  // Generate any new suggestions based on purchase history
  await repo.generateSuggestions();

  // Return all active suggestions
  return repo.getSuggestions();
});

/// Suggestion actions notifier
class SuggestionNotifier extends StateNotifier<AsyncValue<void>> {
  final SuggestionRepository _repository;
  final Ref _ref;

  SuggestionNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// Add suggested item to the shopping list
  Future<void> addToList(RepurchaseSuggestion suggestion) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.markAsAdded(suggestion.id);
      // Refresh suggestions
      _ref.invalidate(suggestionsProvider);
    });
  }

  /// Dismiss a suggestion (snooze for 7 days)
  Future<void> dismiss(RepurchaseSuggestion suggestion) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.dismiss(suggestion.id);
      // Refresh suggestions
      _ref.invalidate(suggestionsProvider);
    });
  }

  /// Refresh suggestions (regenerate from purchase history)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.generateSuggestions();
      _ref.invalidate(suggestionsProvider);
    });
  }
}

final suggestionNotifierProvider =
    StateNotifierProvider<SuggestionNotifier, AsyncValue<void>>((ref) {
  return SuggestionNotifier(
    ref.watch(suggestionRepositoryProvider),
    ref,
  );
});
