class NotificationLog {
  final String id;
  final DateTime? timestamp;
  final String target;
  final String title;
  final String body;
  final String status;
  final String? messageId;
  final String? error;

  const NotificationLog({
    required this.id,
    required this.timestamp,
    required this.target,
    required this.title,
    required this.body,
    required this.status,
    this.messageId,
    this.error,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      target: json['target'] as String? ?? 'unknown',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      messageId: json['messageId'] as String?,
      error: json['error'] as String?,
    );
  }

  bool get isSuccess => status == 'success';
  bool get isAllUsers => target == 'all_users';
}
