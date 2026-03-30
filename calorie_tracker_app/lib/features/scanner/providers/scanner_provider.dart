import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/calorie_entry.dart';
import '../../../data/repositories/api_service.dart';
import '../../../data/repositories/calorie_repository.dart';

enum ScannerState { idle, capturing, predicting, result, saving, error }

class ScannerStateData {
  final ScannerState state;
  final File? imageFile;
  final double? predictedCalories;
  final double? adjustedCalories;
  final String? errorMessage;

  ScannerStateData({
    required this.state,
    this.imageFile,
    this.predictedCalories,
    this.adjustedCalories,
    this.errorMessage,
  });

  ScannerStateData copyWith({
    ScannerState? state,
    File? imageFile,
    double? predictedCalories,
    double? adjustedCalories,
    String? errorMessage,
  }) {
    return ScannerStateData(
      state: state ?? this.state,
      imageFile: imageFile ?? this.imageFile,
      predictedCalories: predictedCalories ?? this.predictedCalories,
      adjustedCalories: adjustedCalories ?? this.adjustedCalories,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get displayCalories => adjustedCalories ?? predictedCalories ?? 0;
}

class ScannerNotifier extends StateNotifier<ScannerStateData> {
  final ApiService _apiService;
  final CalorieRepository _repository;
  final ImagePicker _picker = ImagePicker();

  ScannerNotifier(this._apiService, this._repository)
    : super(ScannerStateData(state: ScannerState.idle));

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        state = ScannerStateData(
          state: ScannerState.capturing,
          imageFile: File(pickedFile.path),
        );
        await _predictCalories(File(pickedFile.path));
      }
    } catch (e) {
      state = ScannerStateData(
        state: ScannerState.error,
        errorMessage: 'Failed to pick image: $e',
      );
    }
  }

  Future<void> captureImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        state = ScannerStateData(
          state: ScannerState.capturing,
          imageFile: File(pickedFile.path),
        );
        await _predictCalories(File(pickedFile.path));
      }
    } catch (e) {
      state = ScannerStateData(
        state: ScannerState.error,
        errorMessage: 'Failed to capture image: $e',
      );
    }
  }

  Future<void> _predictCalories(File imageFile) async {
    try {
      state = state.copyWith(state: ScannerState.predicting);

      final isHealthy = await _apiService.checkHealth();
      if (!isHealthy) {
        state = ScannerStateData(
          state: ScannerState.error,
          imageFile: imageFile,
          errorMessage:
              'Cannot connect to server. Please check your connection.',
        );
        return;
      }

      final result = await _apiService.predictCalories(imageFile);
      state = ScannerStateData(
        state: ScannerState.result,
        imageFile: imageFile,
        predictedCalories: result.calories,
        adjustedCalories: result.calories,
      );
    } catch (e) {
      state = ScannerStateData(
        state: ScannerState.error,
        imageFile: imageFile,
        errorMessage: 'Prediction failed: $e',
      );
    }
  }

  void updateAdjustedCalories(double calories) {
    state = state.copyWith(adjustedCalories: calories);
  }

  Future<void> saveEntry() async {
    if (state.predictedCalories == null) return;

    try {
      state = state.copyWith(state: ScannerState.saving);

      final entry = CalorieEntry(
        timestamp: DateTime.now(),
        imagePath: state.imageFile?.path,
        prediction: state.predictedCalories!,
        userAdjustment: state.adjustedCalories != state.predictedCalories
            ? state.adjustedCalories
            : null,
      );

      await _repository.saveEntry(entry);
      state = ScannerStateData(state: ScannerState.idle);
    } catch (e) {
      state = state.copyWith(
        state: ScannerState.error,
        errorMessage: 'Failed to save entry: $e',
      );
    }
  }

  void reset() {
    state = ScannerStateData(state: ScannerState.idle);
  }

  void dismissError() {
    state = ScannerStateData(state: ScannerState.idle);
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final calorieRepositoryProvider = Provider<CalorieRepository>(
  (ref) => CalorieRepository(),
);

final scannerProvider =
    StateNotifierProvider<ScannerNotifier, ScannerStateData>((ref) {
      return ScannerNotifier(
        ref.watch(apiServiceProvider),
        ref.watch(calorieRepositoryProvider),
      );
    });
