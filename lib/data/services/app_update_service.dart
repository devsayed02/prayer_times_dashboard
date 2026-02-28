import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prayer_times_dashboard/core/constants/fcm_constants.dart';
import 'package:prayer_times_dashboard/data/models/app_update.dart';

class AppUpdateResult {
  final bool success;
  final AppUpdate? data;
  final String? errorMessage;

  const AppUpdateResult({
    required this.success,
    this.data,
    this.errorMessage,
  });
}

class SaveResult {
  final bool success;
  final String message;

  const SaveResult({required this.success, required this.message});
}

class AppUpdateService {
  Future<AppUpdateResult> fetchAppUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(FcmConstants.appUpdateUrl),
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseBody['success'] == true) {
        final data = responseBody['data'] as Map<String, dynamic>? ?? {};
        return AppUpdateResult(
          success: true,
          data: AppUpdate.fromJson(data),
        );
      } else {
        return AppUpdateResult(
          success: false,
          errorMessage: responseBody['message'] as String? ?? 'Unknown error',
        );
      }
    } catch (e) {
      return AppUpdateResult(
        success: false,
        errorMessage: 'Cannot connect to server.\n\nError: $e',
      );
    }
  }

  Future<SaveResult> saveAppUpdate(AppUpdate appUpdate) async {
    try {
      final response = await http.post(
        Uri.parse(FcmConstants.updateAppUpdateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(appUpdate.toJson()),
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      return SaveResult(
        success: responseBody['success'] as bool? ?? false,
        message: responseBody['message'] as String? ?? 'Unknown response',
      );
    } catch (e) {
      return SaveResult(
        success: false,
        message: 'Cannot connect to server.\n\nError: $e',
      );
    }
  }
}
