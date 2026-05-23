import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';

// Models
class DashboardData {
  final double stabilityScore;
  final double shelfLifeMonths;
  final double shelfLifeUncertainty;
  final double degradationRisk;
  final double dissolutionRisk;
  final double environmentalRisk;
  final double confidence;
  final List<double> stabilityTimeline;
  final List<double> stabilityUpper;
  final List<double> stabilityLower;
  final List<AiInsight> aiInsights;
  final List<BatchSummary> recentBatches;

  DashboardData({
    required this.stabilityScore,
    required this.shelfLifeMonths,
    required this.shelfLifeUncertainty,
    required this.degradationRisk,
    required this.dissolutionRisk,
    required this.environmentalRisk,
    required this.confidence,
    required this.stabilityTimeline,
    required this.stabilityUpper,
    required this.stabilityLower,
    required this.aiInsights,
    required this.recentBatches,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stabilityScore: (json['stability_score'] ?? 0.0).toDouble(),
      shelfLifeMonths: (json['shelf_life_months'] ?? 0.0).toDouble(),
      shelfLifeUncertainty: (json['shelf_life_uncertainty'] ?? 0.0).toDouble(),
      degradationRisk: (json['degradation_risk'] ?? 0.0).toDouble(),
      dissolutionRisk: (json['dissolution_risk'] ?? 0.0).toDouble(),
      environmentalRisk: (json['environmental_risk'] ?? 0.0).toDouble(),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      stabilityTimeline: List<double>.from(json['stability_timeline'] ?? []),
      stabilityUpper: List<double>.from(json['stability_upper'] ?? []),
      stabilityLower: List<double>.from(json['stability_lower'] ?? []),
      aiInsights: (json['ai_insights'] as List<dynamic>?)
              ?.map((e) => AiInsight.fromJson(e))
              .toList() ??
          [],
      recentBatches: (json['recent_batches'] as List<dynamic>?)
              ?.map((e) => BatchSummary.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AiInsight {
  final String title;
  final String description;
  final String severity; // 'info', 'warning', 'critical'

  AiInsight({
    required this.title,
    required this.description,
    required this.severity,
  });

  factory AiInsight.fromJson(Map<String, dynamic> json) {
    return AiInsight(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'info',
    );
  }
}

class BatchSummary {
  final String batchId;
  final String formulation;
  final double stabilityScore;
  final double riskScore;
  final String status;

  BatchSummary({
    required this.batchId,
    required this.formulation,
    required this.stabilityScore,
    required this.riskScore,
    required this.status,
  });

  factory BatchSummary.fromJson(Map<String, dynamic> json) {
    return BatchSummary(
      batchId: json['batchId'] ?? '',
      formulation: json['formulation'] ?? '',
      stabilityScore: (json['stabilityScore'] ?? 0.0).toDouble(),
      riskScore: (json['riskScore'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'PENDING',
    );
  }
}

// Provider
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    return loadDashboard();
  }

  Future<DashboardData> loadDashboard() async {
    state = const AsyncLoading();

    try {
      final response = await ref.read(apiClientProvider).get(AppConstants.dashboardEndpoint);
      final data = DashboardData.fromJson(response.data);
      state = AsyncData(data);
      return data;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
