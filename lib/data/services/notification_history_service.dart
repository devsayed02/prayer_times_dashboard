import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prayer_times_dashboard/core/constants/fcm_constants.dart';
import 'package:prayer_times_dashboard/data/models/notification_log.dart';

class NotificationHistoryResult {
  final bool success;
  final List<NotificationLog> logs;
  final String? lastDocId;
  final String? errorMessage;

  const NotificationHistoryResult({
    required this.success,
    this.logs = const [],
    this.lastDocId,
    this.errorMessage,
  });
}

class NotificationHistoryService {
  Future<NotificationHistoryResult> fetchHistory({
    int limit = 50,
    String? startAfterDocId,
  }) async {
    try {
      final uri = Uri.parse(FcmConstants.notificationHistoryUrl).replace(
        queryParameters: {
          'limit': limit.toString(),
          'startAfter': ?startAfterDocId,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseBody['success'] == true) {
        final data = (responseBody['data'] as List<dynamic>?) ?? [];
        final logs = data
            .map(
              (item) => NotificationLog.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return NotificationHistoryResult(
          success: true,
          logs: logs,
          lastDocId: responseBody['lastDocId'] as String?,
        );
      } else {
        return NotificationHistoryResult(
          success: false,
          errorMessage: responseBody['message'] as String? ?? 'Unknown error',
        );
      }
    } catch (e) {
      return NotificationHistoryResult(
        success: false,
        errorMessage: 'Cannot connect to server.\n\nError: $e',
      );
    }
  }
}
