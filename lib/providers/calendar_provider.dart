import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_event_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class CalendarProvider with ChangeNotifier {
  List<CalendarEvent> _events = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool _isLoading = false;
  bool _initialized = false;
  final NotificationService _notificationService = NotificationService();

  List<CalendarEvent> get events => _events;
  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;
  bool get isLoading => _isLoading;

  static const String _storageKey = 'calendar_events';

  CalendarProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Try loading from API first, fallback to local
    try {
      await _loadEventsFromApi();
      debugPrint('📅 CalendarProvider: loaded ${_events.length} events from API');
    } catch (e) {
      debugPrint('📅 API load failed, loading from local: $e');
      try {
        await _loadEventsLocally();
        debugPrint('📅 CalendarProvider: loaded ${_events.length} events from local storage');
      } catch (e2) {
        debugPrint('📅 CalendarProvider init error: $e2');
      }
    }

    _isLoading = false;
    _initialized = true;
    notifyListeners();

    // Init notifications in background (non-blocking)
    try {
      await _notificationService.init();
    } catch (e) {
      debugPrint('📅 Notification init error: $e');
    }
  }

  /// Get events for a specific day
  List<CalendarEvent> getEventsForDay(DateTime day) {
    final dayEvents = _events.where((event) {
      return event.dateTime.year == day.year &&
          event.dateTime.month == day.month &&
          event.dateTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return dayEvents;
  }

  /// Get upcoming events (today + next 7 days)
  List<CalendarEvent> get upcomingEvents {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekLater = now.add(const Duration(days: 7));
    return _events
        .where((e) => e.dateTime.isAfter(todayStart) && e.dateTime.isBefore(weekLater))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  /// Get events that have an alert set (for notification display)
  List<CalendarEvent> get eventsWithAlerts {
    final now = DateTime.now();
    return _events
        .where((e) => e.alertBefore != AlertOption.none && e.dateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  /// Add a new event
  Future<void> addEvent(CalendarEvent event) async {
    // 1. Try saving to API first
    CalendarEvent savedEvent = event;
    try {
      final apiJson = event.toApiJson();
      final response = await ApiService.createCalendarEvent(apiJson);
      // Use the API response to get the MongoDB _id
      savedEvent = CalendarEvent.fromApiJson(response);
      debugPrint('📅 addEvent: saved to API with id ${savedEvent.id}');
    } catch (e) {
      debugPrint('📅 addEvent: API save failed, saving locally only: $e');
      // Keep the local event as-is
    }

    // 2. Add to in-memory list
    _events.add(savedEvent);
    debugPrint('📅 addEvent: added "${savedEvent.title}" — total events: ${_events.length}');

    // 3. Save to local storage
    await _saveEventsLocally();

    // 4. Notify UI to rebuild
    notifyListeners();

    // 5. Schedule notification (non-blocking)
    _scheduleNotification(savedEvent);
  }

  /// Update an existing event
  Future<void> updateEvent(CalendarEvent updatedEvent) async {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      // 1. Try updating on API
      try {
        final apiJson = updatedEvent.toApiJson();
        final response = await ApiService.updateCalendarEvent(updatedEvent.id, apiJson);
        updatedEvent = CalendarEvent.fromApiJson(response);
        debugPrint('📅 updateEvent: updated on API "${updatedEvent.title}"');
      } catch (e) {
        debugPrint('📅 updateEvent: API update failed, saving locally only: $e');
      }

      // 2. Update in-memory
      _events[index] = updatedEvent;
      debugPrint('📅 updateEvent: updated "${updatedEvent.title}"');

      // 3. Save locally
      await _saveEventsLocally();
      notifyListeners();

      // 4. Reschedule notification (non-blocking)
      _cancelNotification(updatedEvent.id);
      _scheduleNotification(updatedEvent);
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    // 1. Try deleting from API
    try {
      await ApiService.deleteCalendarEvent(eventId);
      debugPrint('📅 deleteEvent: deleted from API');
    } catch (e) {
      debugPrint('📅 deleteEvent: API delete failed, removing locally only: $e');
    }

    // 2. Remove from in-memory list
    _events.removeWhere((e) => e.id == eventId);
    debugPrint('📅 deleteEvent: removed event — total events: ${_events.length}');

    // 3. Save locally
    await _saveEventsLocally();
    notifyListeners();

    // 4. Cancel notification (non-blocking)
    _cancelNotification(eventId);
  }

  /// Refresh events from API (with local fallback)
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadEventsFromApi();
      debugPrint('📅 refresh: loaded ${_events.length} events from API');
    } catch (e) {
      debugPrint('📅 refresh: API failed, loading from local: $e');
      await _loadEventsLocally();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== API ====================

  Future<void> _loadEventsFromApi() async {
    final token = await ApiService.getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final jsonList = await ApiService.getCalendarEvents();
    _events = jsonList.map((json) => CalendarEvent.fromApiJson(json)).toList();

    // Also save to local storage for offline access
    await _saveEventsLocally();
  }

  // ==================== LOCAL STORAGE ====================

  Future<void> _saveEventsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _events.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_storageKey, jsonString);
      debugPrint('📅 Saved ${_events.length} events to local storage');
    } catch (e) {
      debugPrint('📅 ERROR saving events: $e');
    }
  }

  Future<void> _loadEventsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List;
        _events = jsonList
            .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('📅 Loaded ${_events.length} events from local storage');
      } else {
        debugPrint('📅 No events found in local storage');
        _events = [];
      }
    } catch (e) {
      debugPrint('📅 ERROR loading events: $e');
      _events = [];
    }
  }

  // ==================== NOTIFICATIONS (non-blocking) ====================

  void _scheduleNotification(CalendarEvent event) {
    Future.microtask(() async {
      try {
        await _notificationService.scheduleEventAlert(event);
      } catch (e) {
        debugPrint('📅 Notification schedule error: $e');
      }
    });
  }

  void _cancelNotification(String eventId) {
    Future.microtask(() async {
      try {
        await _notificationService.cancelEventAlert(eventId);
      } catch (e) {
        debugPrint('📅 Notification cancel error: $e');
      }
    });
  }
}
