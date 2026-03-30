import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

class PredictionResult {
  final String filename;
  final double calories;

  PredictionResult({required this.filename, required this.calories});
}

class ApiService {
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.healthEndpoint}'),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<PredictionResult> predictCalories(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.predictEndpoint}'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(
      streamedResponse,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PredictionResult(
        filename: data['filename'] ?? 'unknown',
        calories: (data['calories'] as num).toDouble(),
      );
    } else {
      throw Exception('Failed to predict calories: ${response.statusCode}');
    }
  }
}
