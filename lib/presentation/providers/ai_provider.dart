import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ai_service.dart';

/// AI service provider
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

/// Categorize an item - returns category and confidence
final categorizeItemProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, itemName) async {
    final aiService = ref.watch(aiServiceProvider);
    return aiService.categorizeItem(itemName);
  },
);
