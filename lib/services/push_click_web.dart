import 'dart:async';
import 'dart:html' as html;

Stream<Map<String, dynamic>> pushClickMessages() {
  final controller = StreamController<Map<String, dynamic>>.broadcast();

  final sw = html.window.navigator.serviceWorker;
  if (sw == null) {
    controller.close();
    return controller.stream;
  }

  sw.onMessage.listen((event) {
    try {
      final data = event.data;
      if (data is Map) {
        controller.add(Map<String, dynamic>.from(data as Map));
      }
    } catch (_) {
      // ignore
    }
  });

  return controller.stream;
}
