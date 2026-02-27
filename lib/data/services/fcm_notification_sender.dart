import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prayer_times_dashboard/core/constants/fcm_constants.dart';

enum SendTarget { allUsers, singleUser }

class FcmSendResult {
  final bool success;
  final String message;

  const FcmSendResult({required this.success, required this.message});
}

class FcmNotificationSender {
  Future<FcmSendResult> sendNotification({
    required SendTarget target,
    required String title,
    required String body,
    String? fcmToken,
    String imageUrl = '',
    String actionUrl = '',
  }) async {
    if (target == SendTarget.singleUser &&
        (fcmToken == null || fcmToken.isEmpty)) {
      return const FcmSendResult(
        success: false,
        message: 'FCM token is required for single user notification',
      );
    }

    final Map<String, dynamic> payload = {
      'target': target == SendTarget.allUsers ? 'all_users' : 'single_user',
      'title': title,
      'body': body,
      'fcmToken': ?fcmToken,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
    };

    try {
      final response = await http.post(
        Uri.parse(FcmConstants.sendNotificationUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      return FcmSendResult(
        success: responseBody['success'] as bool? ?? false,
        message: responseBody['message'] as String? ?? 'Unknown response',
      );
    } catch (e) {
      return FcmSendResult(
        success: false,
        message:
            'Cannot connect to server. Is it running on localhost:8080?\n\nError: $e',
      );
    }
  }
}
