import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'enumerate_items.dart';
import 'network_event.dart';
import 'network_logger.dart';

/// Overlay for [NetworkLoggerButton].
class NetworkLoggerOverlay extends StatelessWidget {
  NetworkLoggerOverlay._({Key? key}) : super(key: key);

  /// Attach overlay to specified [context].
  static OverlayEntry attachTo(
    BuildContext context, {
    bool rootOverlay = true,
  }) {
    // create overlay entry
    var entry = OverlayEntry(
      builder: (context) => NetworkLoggerOverlay._(),
    );
    // insert on next frame
    Future.delayed(Duration.zero, () {
      Overlay.of(context, rootOverlay: rootOverlay)?.insert(entry);
    });
    // return
    return entry;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(right: 30, bottom: 100, child: NetworkLoggerButton());
  }
}

/// [FloatingActionButton] that opens [NetworkLoggerScreen] when pressed.
class NetworkLoggerButton extends StatefulWidget {
  final NetworkEventList? eventList;
  final Duration blinkPeriod;
  final Color color;

  NetworkLoggerButton({
    Key? key,
    this.color = Colors.deepPurple,
    this.blinkPeriod = const Duration(seconds: 1, microseconds: 500),
    NetworkEventList? eventList,
  })  : this.eventList = eventList ?? NetworkLogger.instance,
        super(key: key);

  @override
  _NetworkLoggerButtonState createState() => _NetworkLoggerButtonState();
}

class _NetworkLoggerButtonState extends State<NetworkLoggerButton> {
  StreamSubscription? _subscription;
  Timer? _blinkTimer;
  bool _visible = true;
  int _blink = 0;

  Future<void> _press() async {
    setState(() {
      _visible = false;
    });
    try {
      await NetworkLoggerScreen.open(context);
    } finally {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    }
  }

  @override
  void initState() {
    _subscription = NetworkLogger.instance.stream.listen((event) {
      if (event != null && mounted) {
        setState(() {
          _blink = _blink % 2 == 0 ? 6 : 5;
        });
      }
    });

    _blinkTimer = Timer.periodic(widget.blinkPeriod, (timer) {
      if (_blink > 0 && mounted) {
        setState(() {
          _blink--;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _visible
        ? FloatingActionButton(
            child: Icon(
              (_blink % 2 == 0) ? Icons.cloud : Icons.cloud_queue,
              color: Colors.white,
            ),
            onPressed: _press,
            backgroundColor: widget.color,
          )
        : SizedBox();
  }
}

/// Screen that displays log entries list.
class NetworkLoggerScreen extends StatelessWidget {
  NetworkLoggerScreen({Key? key, NetworkEventList? eventList})
      : this.eventList = eventList ?? NetworkLogger.instance,
        super(key: key);

  /// Event list to listen for event changes.
  final NetworkEventList eventList;

  /// Opens screen.
  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetworkLoggerScreen(),
      ),
    );
  }

  final TextEditingController searchController =
      TextEditingController(text: null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Logs'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => eventList.clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            controller: searchController,
            onChanged: (text) {
              eventList.updated(NetworkEvent());
            },
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                Icons.search,
                color: Colors.black26,
              ),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(10.0),
                ),
              ),
              hintText: "过滤",
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
                borderRadius: const BorderRadius.all(
                  const Radius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: eventList.stream,
              builder: (context, snapshot) {
                //过滤关键字
                final events = eventList.events.where((element) {
                  if (searchController.text.length > 0) {
                    return (element.request?.uri
                            .contains(searchController.text) ??
                        false);
                  }
                  return true;
                }).toList();
                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: enumerateItems<NetworkEvent>(
                    events,
                    (context, item) => ListTile(
                      key: ValueKey(item.request),
                      title: Text(
                        item.request!.method,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        item.request!.uri.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: Icon(
                        item.error == null
                            ? (item.response == null
                                ? Icons.hourglass_empty
                                : Icons.done)
                            : Icons.error,
                      ),
                      trailing: AutoUpdate(
                        duration: Duration(seconds: 1),
                        builder: (context) =>
                            Text(_timeDifference(item.timestamp!)),
                      ),
                      onTap: () => NetworkLoggerEventScreen.open(
                        context,
                        item,
                        eventList,
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

String _timeDifference(DateTime time, [DateTime? origin]) {
  origin ??= DateTime.now();
  var delta = origin.difference(time);
  if (delta.inSeconds < 90) {
    return '${delta.inSeconds} s';
  } else if (delta.inMinutes < 90) {
    return '${delta.inMinutes} m';
  } else {
    return '${delta.inHours} h';
  }
}

final _jsonEncoder = JsonEncoder.withIndent('  ');

/// Screen that displays log entry details.
class NetworkLoggerEventScreen extends StatelessWidget {
  const NetworkLoggerEventScreen({Key? key, required this.event})
      : super(key: key);

  /// Opens screen.
  static Future<void> open(
    BuildContext context,
    NetworkEvent event,
    NetworkEventList eventList,
  ) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamBuilder(
          stream: eventList.stream.where((item) => item.event == event),
          builder: (context, snapshot) => NetworkLoggerEventScreen(
            event: event,
          ),
        ),
      ),
    );
  }

  /// Which event to display details for.
  final NetworkEvent event;

  Widget buildBodyViewer(BuildContext context, dynamic body) {
    String text;
    if (body == null) {
      text = '';
    } else if (body is String) {
      text = body;
    } else if (body is List || body is Map) {
      text = _jsonEncoder.convert(body);
    } else {
      text = body.toString();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: text));
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text('Copied to clipboard'),
            behavior: SnackBarBehavior.floating,
          ));
        },
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontFamilyFallback: ['sans-serif'],
          ),
        ),
      ),
    );
  }

  Widget buildHeadersViewer(
    BuildContext context,
    List<MapEntry<String, String>> headers,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: headers.map((e) => SelectableText(e.key)).toList(),
          ),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: headers.map((e) => SelectableText(e.value)).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildRequestView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 15),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
          child: Text('URL', style: Theme.of(context).textTheme.caption),
        ),
        SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.request!.method,
                style: Theme.of(context).textTheme.bodyText1,
              ),
              SizedBox(width: 15),
              Expanded(child: SelectableText(event.request!.uri.toString())),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
          child: Text('TIMESTAMP', style: Theme.of(context).textTheme.caption),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(event.timestamp.toString()),
        ),
        if (event.request!.headers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            child: Text('HEADERS', style: Theme.of(context).textTheme.caption),
          ),
          buildHeadersViewer(context, event.request!.headers.entries),
        ],
        if (event.error != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            child: Text('ERROR', style: Theme.of(context).textTheme.caption),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              event.error.toString(),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
          child: Text('BODY', style: Theme.of(context).textTheme.caption),
        ),
        buildBodyViewer(context, event.request!.data),
      ],
    );
  }

  Widget buildResponseView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 15),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
          child: Text('RESULT', style: Theme.of(context).textTheme.caption),
        ),
        SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                event.response!.statusCode.toString(),
                style: Theme.of(context).textTheme.bodyText1,
              ),
              SizedBox(width: 15),
              Expanded(child: Text(event.response!.statusMessage)),
            ],
          ),
        ),
        if (event.response?.headers.isNotEmpty ?? false) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
            child: Text('HEADERS', style: Theme.of(context).textTheme.caption),
          ),
          buildHeadersViewer(
            context,
            event.response?.headers.entries ?? [],
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
          child: Text('BODY', style: Theme.of(context).textTheme.caption),
        ),
        buildBodyViewer(context, event.response?.data),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showResponse = event.response != null;

    Widget? bottom;
    if (showResponse) {
      bottom = TabBar(tabs: [
        Tab(text: 'Request'),
        Tab(text: 'Response'),
      ]);
    }

    return DefaultTabController(
      initialIndex: 0,
      length: showResponse ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Log Entry'),
          bottom: (bottom as PreferredSizeWidget?),
        ),
        body: Builder(
            builder: (context) => TabBarView(
                  children: <Widget>[
                    buildRequestView(context),
                    if (showResponse) buildResponseView(context),
                  ],
                )),
      ),
    );
  }
}

/// Widget builder that re-builds widget repeatedly with [duration] interval.
class AutoUpdate extends StatefulWidget {
  const AutoUpdate({Key? key, required this.duration, required this.builder})
      : super(key: key);

  /// Re-build interval.
  final Duration duration;

  /// Widget builder to build widget.
  final WidgetBuilder builder;

  @override
  _AutoUpdateState createState() => _AutoUpdateState();
}

class _AutoUpdateState extends State<AutoUpdate> {
  Timer? _timer;

  void _setTimer() {
    _timer = Timer.periodic(widget.duration, (timer) {
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(AutoUpdate old) {
    if (old.duration != widget.duration) {
      _timer?.cancel();
      _setTimer();
    }
    super.didUpdateWidget(old);
  }

  @override
  void initState() {
    _setTimer();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
