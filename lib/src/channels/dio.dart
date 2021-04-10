import 'package:dio/dio.dart' as dio;

import '../network_event.dart';
import '../network_logger.dart';

class DioNetworkLogger extends dio.Interceptor {
  final NetworkEventList eventList;
  final _requests = <dio.RequestOptions, NetworkEvent>{};

  DioNetworkLogger({NetworkEventList? eventList})
      : this.eventList = eventList ?? NetworkLogger.instance;

  @override
  Future<void> onRequest(
      dio.RequestOptions options, dio.RequestInterceptorHandler handler) async {
    super.onRequest(options, handler);
    eventList.add(_requests[options] = NetworkEvent.now(
      request: options.toRequest(),
      error: null,
      response: null,
    ));
    return Future.value(options);
  }

  @override
  void onResponse(
    dio.Response response,
    dio.ResponseInterceptorHandler handler,
  ) {
    super.onResponse(response, handler);
    final req = response.requestOptions.toRequest();
    var event = _requests[req];
    if (event != null) {
      _requests.remove(req);
      eventList.updated(event..response = response.toResponse());
    } else {
      eventList.add(NetworkEvent.now(
        request: req,
        response: response.toResponse(),
      ));
    }
  }

  @override
  void onError(dio.DioError err, dio.ErrorInterceptorHandler handler) {
    super.onError(err, handler);
    final req = err.requestOptions.toRequest();
    var event = _requests[req];
    if (event != null) {
      _requests.remove(req);
      eventList.updated(event..error = err.toNetworkError());
    } else {
      eventList.add(NetworkEvent.now(
        request: req,
        response: err.response?.toResponse(),
        error: err.toNetworkError(),
      ));
    }
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
        statusCode: statusCode ?? -1,
        statusMessage: statusMessage ?? 'unkown',
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
