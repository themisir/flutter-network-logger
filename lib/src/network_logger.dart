import 'dart:async';

import 'network_event.dart';

class NetworkEventList {
  final events = <NetworkEvent>[];
  final _controller = StreamController<UpdateEvent>.broadcast();

  Stream<UpdateEvent> get stream => _controller.stream;

  void updated(NetworkEvent event) {
    _controller.add(UpdateEvent(event));
  }

  void add(NetworkEvent event) {
    events.insert(0, event);
    _controller.add(UpdateEvent(event));
  }

  void clear() {
    events.clear();
    _controller.add(UpdateEvent.clear());
  }

  void dispose() {
    _controller.close();
  }
}

class UpdateEvent {
  const UpdateEvent(this.event);
  const UpdateEvent.clear() : this.event = null;

  final NetworkEvent event;
}

class NetworkLogger extends NetworkEventList {
  static final NetworkLogger instance = NetworkLogger();
}
