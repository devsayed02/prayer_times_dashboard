import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:prayer_times_dashboard/core/constants/fcm_constants.dart';
import 'package:prayer_times_dashboard/data/models/islamic_event.dart';

class EventsResult {
  final bool success;
  final List<IslamicEvent> events;
  final String? errorMessage;

  const EventsResult({
    required this.success,
    this.events = const [],
    this.errorMessage,
  });
}

class ManageEventResult {
  final bool success;
  final String message;
  final String? id;

  const ManageEventResult({
    required this.success,
    required this.message,
    this.id,
  });
}

class EventsService {
  Future<EventsResult> fetchEvents(int year) async {
    try {
      final uri = Uri.parse(FcmConstants.eventsUrl).replace(
        queryParameters: {'year': year.toString()},
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (responseBody['success'] == true) {
        final data = (responseBody['data'] as List<dynamic>?) ?? [];
        final events = data
            .map((item) =>
                IslamicEvent.fromJson(item as Map<String, dynamic>))
            .toList();

        return EventsResult(success: true, events: events);
      } else {
        return EventsResult(
          success: false,
          errorMessage: responseBody['message'] as String? ?? 'Unknown error',
        );
      }
    } catch (e) {
      return EventsResult(
        success: false,
        errorMessage: 'Cannot connect to server.\n\nError: $e',
      );
    }
  }

  Future<ManageEventResult> createEvent(IslamicEvent event) async {
    return _manage({
      'action': 'create',
      ...event.toJson(),
    });
  }

  Future<ManageEventResult> updateEvent(IslamicEvent event) async {
    return _manage({
      'action': 'update',
      'id': event.id,
      ...event.toJson(),
    });
  }

  Future<ManageEventResult> deleteEvent(String id) async {
    return _manage({'action': 'delete', 'id': id});
  }

  Future<ManageEventResult> toggleEvent(String id) async {
    return _manage({'action': 'toggle', 'id': id});
  }

  Future<ManageEventResult> _manage(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(FcmConstants.manageEventUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      return ManageEventResult(
        success: responseBody['success'] as bool? ?? false,
        message: responseBody['message'] as String? ?? 'Unknown response',
        id: responseBody['id'] as String?,
      );
    } catch (e) {
      return ManageEventResult(
        success: false,
        message: 'Cannot connect to server.\n\nError: $e',
      );
    }
  }
}
