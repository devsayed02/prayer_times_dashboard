import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prayer_times_dashboard/core/constants/fcm_constants.dart';
import 'package:prayer_times_dashboard/data/models/user_analytics.dart';

class AnalyticsResult {
  final bool success;
  final UserAnalytics? data;
  final String? errorMessage;

  const AnalyticsResult({
    required this.success,
    this.data,
    this.errorMessage,
  });
}

class AnalyticsService {
  Future<AnalyticsResult> fetchAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse(FcmConstants.analyticsUrl),
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseBody['success'] == true) {
        final data = responseBody['data'] as Map<String, dynamic>? ?? {};
        return AnalyticsResult(
          success: true,
          data: UserAnalytics.fromJson(data),
        );
      } else {
        return AnalyticsResult(
          success: false,
          errorMessage: responseBody['message'] as String? ?? 'Unknown error',
        );
      }
    } catch (e) {
      return AnalyticsResult(
        success: false,
        errorMessage: 'Cannot connect to server.\n\nError: $e',
      );
    }
  }
}
