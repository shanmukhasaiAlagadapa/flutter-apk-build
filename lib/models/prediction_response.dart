class PredictionResponse {
  final String diagnosis;
  final double? confidence;
  final double? riskScore;
  final String? recommendation;
  final Map<String, dynamic> raw;

  PredictionResponse({
    required this.diagnosis,
    required this.raw,
    this.confidence,
    this.riskScore,
    this.recommendation,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    final diagnosis =
        (json['diagnosis'] ??
                json['prediction'] ??
                json['result'] ??
                'Unknown')
            .toString();

    return PredictionResponse(
      diagnosis: diagnosis,
      confidence: toDouble(json['confidence']),
      riskScore: toDouble(json['risk_score'] ?? json['riskScore']),
      recommendation: json['recommendation']?.toString(),
      raw: json,
    );
  }
}
