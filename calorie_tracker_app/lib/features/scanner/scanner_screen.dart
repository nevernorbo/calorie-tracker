import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import 'providers/scanner_provider.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Snap & Track')),
      body: _buildBody(context, ref, scannerState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ScannerStateData state,
  ) {
    switch (state.state) {
      case ScannerState.idle:
        return _buildIdleView(context, ref);
      case ScannerState.capturing:
      case ScannerState.predicting:
        return _buildLoadingView(state);
      case ScannerState.result:
        return _buildResultView(context, ref, state);
      case ScannerState.saving:
        return _buildSavingView();
      case ScannerState.error:
        return _buildErrorView(context, ref, state);
    }
  }

  Widget _buildIdleView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.emerald50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: AppTheme.emerald600,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Track Your Calories',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Take a photo of your meal to get an AI-powered calorie estimate',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(scannerProvider.notifier).captureImage(),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(scannerProvider.notifier).pickImageFromGallery(),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(ScannerStateData state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (state.imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                state.imageFile!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(color: AppTheme.emerald600),
          const SizedBox(height: 16),
          Text(
            state.state == ScannerState.capturing
                ? 'Preparing image...'
                : 'Analyzing calories...',
            style: const TextStyle(fontSize: 16, color: AppTheme.slate600),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(
    BuildContext context,
    WidgetRef ref,
    ScannerStateData state,
  ) {
    final caloriesController = TextEditingController(
      text: state.displayCalories.toStringAsFixed(1),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.imageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                state.imageFile!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.restaurant_menu,
                    size: 48,
                    color: AppTheme.emerald600,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estimated Calories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.predictedCalories?.toStringAsFixed(1) ?? '0'} kcal',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.emerald600,
                    ),
                  ),
                  if (state.adjustedCalories != state.predictedCalories)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Adjusted: ${state.adjustedCalories?.toStringAsFixed(1)} kcal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.slate500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adjust Calories (optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      suffixText: 'kcal',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    onChanged: (value) {
                      final calories = double.tryParse(value);
                      if (calories != null) {
                        ref
                            .read(scannerProvider.notifier)
                            .updateAdjustedCalories(calories);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(scannerProvider.notifier).reset(),
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(scannerProvider.notifier).saveEntry();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Entry saved successfully!'),
                          backgroundColor: AppTheme.emerald600,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Entry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.emerald600),
          SizedBox(height: 16),
          Text(
            'Saving entry...',
            style: TextStyle(fontSize: 16, color: AppTheme.slate600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    WidgetRef ref,
    ScannerStateData state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text('Oops!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      ref.read(scannerProvider.notifier).dismissError(),
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (state.imageFile != null) {
                      ref.read(scannerProvider.notifier).pickImageFromGallery();
                    } else {
                      ref.read(scannerProvider.notifier).captureImage();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
