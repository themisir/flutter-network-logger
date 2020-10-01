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
    eventList.add(_requests[options] = NetworkEvent.now(
      request: options.toRequest(),
    ));
    return Future.value(options);
  }

  @override
  Future onResponse(dio.Response response) {
    var event = _requests[response.request];
    if (event != null) {
      _requests.remove(response.request);
      eventList.updated(event..response = response.toResponse());
    } else {
      eventList.add(NetworkEvent.now(
        request: response.request.toRequest(),
        response: response.toResponse(),
      ));
    }
    return Future.value(response);
  }

  @override
  Future onError(dio.DioError err) {
    var event = _requests[err.request];
    if (event != null) {
      _requests.remove(err.request);
      eventList.updated(event..error = err.toNetworkError());
    } else {
      eventList.add(NetworkEvent.now(
        request: err.request.toRequest(),
        response: err.response?.toResponse(),
        error: err.toNetworkError(),
      ));
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
  Response toResponse() => Response(
        data: data,
        statusCode: statusCode,
        statusMessage: statusMessage,
        headers: Headers(
          headers.map.entries.fold<List<MapEntry<String, String>>>(
            [],
            (p, e) => p..addAll(e.value.map((v) => MapEntry(e.key, v))),
          ),
        ),
      );
}

extension _DioErrorX on dio.DioError {
  NetworkError toNetworkError() => NetworkError(message: toString());
}
