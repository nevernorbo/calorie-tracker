import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/calorie_entry.dart';
import '../../scanner/providers/scanner_provider.dart';

final historyProvider = FutureProvider<Map<DateTime, List<CalorieEntry>>>((
  ref,
) async {
  final repository = ref.watch(calorieRepositoryProvider);
  return repository.getEntriesGroupedByDay();
});
