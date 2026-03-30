import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/calorie_entry.dart';
import 'providers/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(historyProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (groupedEntries) => groupedEntries.isEmpty
            ? _buildEmptyView(context)
            : _buildHistoryList(context, ref, groupedEntries),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.emerald600),
        ),
        error: (error, stack) => _buildErrorView(context, ref, error),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.slate100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 64,
                color: AppTheme.slate400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Entries Yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Start tracking your calories by taking a photo of your meals',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(historyProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    WidgetRef ref,
    Map<DateTime, List<CalorieEntry>> groupedEntries,
  ) {
    final sortedDates = groupedEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final totalCalories = groupedEntries.values
        .expand((entries) => entries)
        .fold(0.0, (sum, entry) => sum + entry.finalCalories);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildSummaryCard(
            context,
            totalCalories,
            groupedEntries.length,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final date = sortedDates[index];
            final entries = groupedEntries[date]!;
            return _buildDaySection(context, date, entries);
          }, childCount: sortedDates.length),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalCalories,
    int entryCount,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        color: AppTheme.emerald600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalCalories.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppTheme.emerald600),
                      ),
                      Text(
                        'Total kcal',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 60, color: AppTheme.slate200),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.restaurant,
                        color: AppTheme.slate600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entryCount.toString(),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: AppTheme.slate700),
                      ),
                      Text(
                        'Entries',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<CalorieEntry> entries,
  ) {
    final dateFormat = DateFormat('EEEE, MMM d');
    final dayTotal = entries.fold(
      0.0,
      (sum, entry) => sum + entry.finalCalories,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateHeader(date, dateFormat),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppTheme.slate700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.emerald100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${dayTotal.toStringAsFixed(0)} kcal',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppTheme.emerald700),
                ),
              ),
            ],
          ),
        ),
        ...entries.map((entry) => _buildEntryCard(context, entry)),
      ],
    );
  }

  String _formatDateHeader(DateTime date, DateFormat format) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    }
    return format.format(date);
  }

  Widget _buildEntryCard(BuildContext context, CalorieEntry entry) {
    final timeFormat = DateFormat('h:mm a');
    final wasAdjusted = entry.userAdjustment != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: wasAdjusted ? AppTheme.emerald100 : AppTheme.slate100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            wasAdjusted ? Icons.edit_note : Icons.restaurant,
            color: wasAdjusted ? AppTheme.emerald600 : AppTheme.slate500,
          ),
        ),
        title: Row(
          children: [
            Text(
              '${entry.finalCalories.toStringAsFixed(1)} kcal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.emerald700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (wasAdjusted)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.emerald100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'adjusted',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.emerald600),
                ),
              ),
          ],
        ),
        subtitle: Text(
          timeFormat.format(entry.timestamp),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: wasAdjusted
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'AI: ${entry.prediction.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.slate400,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
