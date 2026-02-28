class IslamicEvent {
  final String id;
  final String title;
  final String description;
  final String holidayType;
  final String date;
  final String colorHex;
  final int year;
  final bool isActive;

  const IslamicEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.holidayType,
    required this.date,
    required this.colorHex,
    required this.year,
    required this.isActive,
  });

  factory IslamicEvent.fromJson(Map<String, dynamic> json) {
    return IslamicEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      holidayType: json['holiday_type'] as String? ?? '',
      date: json['date'] as String? ?? '',
      colorHex: json['color'] as String? ?? '#FF4CAF50',
      year: json['year'] as int? ?? DateTime.now().year,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'holiday_type': holidayType,
      'date': date,
      'color': colorHex,
      'year': year,
      'is_active': isActive,
    };
  }

  IslamicEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? holidayType,
    String? date,
    String? colorHex,
    int? year,
    bool? isActive,
  }) {
    return IslamicEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      holidayType: holidayType ?? this.holidayType,
      date: date ?? this.date,
      colorHex: colorHex ?? this.colorHex,
      year: year ?? this.year,
      isActive: isActive ?? this.isActive,
    );
  }
}
