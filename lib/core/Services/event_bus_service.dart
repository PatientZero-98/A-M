import 'dart:async';

/// A simple event bus implementation to facilitate communication between widgets
class EventBusService {
  static final EventBusService _instance = EventBusService._internal();
  
  factory EventBusService() {
    return _instance;
  }
  
  EventBusService._internal();
  
  final StreamController _streamController = StreamController.broadcast();
  
  /// Get the stream to listen to events
  Stream get stream => _streamController.stream;
  
  /// Fire an event with a specific event name and optional data
  void fire(String eventName, [dynamic data]) {
    _streamController.add({'event': eventName, 'data': data});
  }
  
  /// Dispose the stream controller
  void dispose() {
    _streamController.close();
  }
}

/// Constants for event names
class AppEvents {
  static const String tracksUpdated = 'tracks_updated';
  static const String cardsUpdated = 'cards_updated';
}
