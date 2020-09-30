class NetworkEvent {
  NetworkEvent({this.request, this.response, this.error, this.timestamp});
  NetworkEvent.now({this.request, this.response, this.error})
      : this.timestamp = DateTime.now();
  NetworkEvent.request(this.request, [DateTime timestamp])
      : this.response = null,
        this.error = null,
        this.timestamp = timestamp ?? DateTime.now();
  NetworkEvent.response(this.response, [DateTime timestamp])
      : this.request = response.request,
        this.error = null,
        this.timestamp = timestamp ?? DateTime.now();
  NetworkEvent.error(this.error, [DateTime timestamp])
      : this.request = error.request,
        this.response = error.response,
        this.timestamp = timestamp ?? DateTime.now();

  Request request;
  Response response;
  NetworkError error;
  DateTime timestamp;
}

class Headers {
  Headers(Iterable<MapEntry<String, String>> entries)
      : this.entries = entries.toList();
  Headers.fromMap(Map<String, String> map) : this.entries = map.entries;

  final List<MapEntry<String, String>> entries;

  bool get isNotEmpty => entries.isNotEmpty;
  bool get isEmpty => entries.isEmpty;

  Iterable<T> map<T>(T Function(String key, String value) cb) =>
      entries.map((e) => cb(e.key, e.value));
}

class Request {
  Request({
    this.uri,
    this.method,
    this.headers,
    this.data,
  });

  final String uri;
  final String method;
  final Headers headers;
  final dynamic data;
}

class Response {
  Response({
    this.request,
    this.headers,
    this.statusCode,
    this.statusMessage,
    this.data,
  });

  final Request request;
  final Headers headers;
  final int statusCode;
  final String statusMessage;
  final dynamic data;
}

class NetworkError {
  NetworkError({this.request, this.response, this.message});

  final Request request;
  final Response response;
  final String message;

  @override
  String toString() => message;
}
