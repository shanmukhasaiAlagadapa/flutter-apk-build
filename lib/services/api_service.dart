import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/prediction_response.dart';

class ApiService {
  static Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  static Future<PredictionResponse> analyzeMri({
    required String patientId,
    required String patientName,
    required String age,
    required String gender,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/predict'))
      ..fields['patient_id'] = patientId
      ..fields['patient_name'] = patientName
      ..fields['age'] = age
      ..fields['gender'] = gender
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PredictionResponse.fromJson(data);
    }

    String errorMessage = 'Request failed (${response.statusCode})';
    try {
      final err = jsonDecode(response.body);
      if (err is Map && err['error'] != null) {
        errorMessage = err['error'].toString();
      }
    } catch (_) {}

    throw Exception(errorMessage);
  }
}
