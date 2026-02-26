import 'package:flutter/material.dart';

/// Types d'├®v├®nements m├®dicaux
enum EventType {
  consultation,
  operation,
  note,
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.consultation:
        return 'Consultation';
      case EventType.operation:
        return 'Op├®ration';
      case EventType.note:
        return 'Note';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.consultation:
        return Icons.medical_services_rounded;
      case EventType.operation:
        return Icons.healing_rounded;
      case EventType.note:
        return Icons.note_alt_rounded;
    }
  }

  Color get color {
    switch (this) {
      case EventType.consultation:
        return const Color(0xFF7C3AED); // Purple
      case EventType.operation:
        return const Color(0xFFEF4444); // Red
      case EventType.note:
        return const Color(0xFF0EA5E9); // Blue
    }
  }

  Color get lightColor {
    switch (this) {
      case EventType.consultation:
        return const Color(0xFFF3E8FF);
      case EventType.operation:
        return const Color(0xFFFEE2E2);
      case EventType.note:
        return const Color(0xFFE0F2FE);
    }
  }
}

/// Options d'alerte avant l'├®v├®nement
enum AlertOption {
  none,
  min5,
  min15,
  min30,
  hour1,
  day1,
}

extension AlertOptionExtension on AlertOption {
  String get displayName {
    switch (this) {
      case AlertOption.none:
        return 'Aucune';
      case AlertOption.min5:
        return '5 minutes avant';
      case AlertOption.min15:
        return '15 minutes avant';
      case AlertOption.min30:
        return '30 minutes avant';
      case AlertOption.hour1:
        return '1 heure avant';
      case AlertOption.day1:
        return '1 jour avant';
    }
  }

  Duration get duration {
    switch (this) {
      case AlertOption.none:
        return Duration.zero;
      case AlertOption.min5:
        return const Duration(minutes: 5);
      case AlertOption.min15:
        return const Duration(minutes: 15);
      case AlertOption.min30:
        return const Duration(minutes: 30);
      case AlertOption.hour1:
        return const Duration(hours: 1);
      case AlertOption.day1:
        return const Duration(days: 1);
    }
  }
}

/// Mod├¿le d'├®v├®nement calendrier
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final DateTime? endTime;
  final EventType type;
  final AlertOption alertBefore;
  final String? patientName;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.endTime,
    required this.type,
    this.alertBefore = AlertOption.none,
    this.patientName,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    DateTime? endTime,
    EventType? type,
    AlertOption? alertBefore,
    String? patientName,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      alertBefore: alertBefore ?? this.alertBefore,
      patientName: patientName ?? this.patientName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'type': type.index,
      'alertBefore': alertBefore.index,
      'patientName': patientName,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      type: EventType.values[json['type'] ?? 0],
      alertBefore: AlertOption.values[json['alertBefore'] ?? 0],
      patientName: json['patientName'],
    );
  }

  /// Convert to JSON for API (uses string enum values matching backend)
  Map<String, dynamic> toApiJson() {
    const typeMap = {
      EventType.consultation: 'consultation',
      EventType.operation: 'operation',
      EventType.note: 'note',
    };
    const alertMap = {
      AlertOption.none: 'none',
      AlertOption.min5: 'min5',
      AlertOption.min15: 'min15',
      AlertOption.min30: 'min30',
      AlertOption.hour1: 'hour1',
      AlertOption.day1: 'day1',
    };

    final map = <String, dynamic>{
      'title': title,
      'dateTime': dateTime.toIso8601String(),
      'type': typeMap[type],
      'alertBefore': alertMap[alertBefore],
    };
    if (description != null) map['description'] = description;
    if (endTime != null) map['endTime'] = endTime!.toIso8601String();
    if (patientName != null) map['patientName'] = patientName;
    return map;
  }

  /// Create from API response JSON (handles MongoDB _id and string enums)
  factory CalendarEvent.fromApiJson(Map<String, dynamic> json) {
    const typeMap = {
      'consultation': EventType.consultation,
      'operation': EventType.operation,
      'note': EventType.note,
    };
    const alertMap = {
      'none': AlertOption.none,
      'min5': AlertOption.min5,
      'min15': AlertOption.min15,
      'min30': AlertOption.min30,
      'hour1': AlertOption.hour1,
      'day1': AlertOption.day1,
    };

    return CalendarEvent(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      type: typeMap[json['type']] ?? EventType.consultation,
      alertBefore: alertMap[json['alertBefore']] ?? AlertOption.none,
      patientName: json['patientName'],
    );
  }
}

