import 'package:dio/dio.dart' as dio;
import '../network_event.dart';
import '../network_logger.dart';

class DioNetworkLogger extends dio.Interceptor {
  final NetworkEventList eventList;
  final _requests = <dio.RequestOptions, NetworkEvent>{};

  DioNetworkLogger({NetworkEventList eventList})
      : this.eventList = eventList ?? NetworkLogger.instance;

  @override
  Future onRequest(dio.RequestOptions options) {
    var event = NetworkEvent.request(options.toRequest());
    eventList.add(_requests[options] = event);
    return Future.value(options);
  }

  @override
  Future onResponse(dio.Response response) {
    var event = _requests[response.request];
    if (event != null) {
      event.response = response.toResponse(event.request);
      eventList.updated(event);
    } else {
      var request = response.request.toRequest();
      eventList.add(NetworkEvent.response(response.toResponse(request)));
    }
    return Future.value(response);
  }

  @override
  Future onError(dio.DioError err) {
    var event = _requests[err.request];
    if (event != null) {
      event.error = NetworkError(
        request: event.request,
        response: err.response?.toResponse(event.request),
        message: err.toString(),
      );
      eventList.updated(event);
    } else {
      var request = err.request.toRequest();
      eventList.add(NetworkEvent.error(NetworkError(
        request: request,
        response: err.response?.toResponse(request),
        message: err.toString(),
      )));
    }
    return Future.value(err);
  }
}

extension _RequestOptionsX on dio.RequestOptions {
  Request toRequest() => Request(
        uri: uri.toString(),
        data: data,
        method: method,
        headers: Headers(headers.entries.map(
          (kv) => MapEntry(kv.key, '${kv.value}'),
        )),
      );
}

extension _ResponseX on dio.Response {
  Response toResponse(Request request) => Response(
        data: data,
        statusCode: statusCode,
        statusMessage: statusMessage,
        request: request,
        headers: Headers(
          headers.map.entries.fold<List<MapEntry<String, String>>>(
            [],
            (p, e) => p..addAll(e.value.map((v) => MapEntry(e.key, v))),
          ),
        ),
      );
}
