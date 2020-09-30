# Network Logger

## 📷 Screenshots

|![Screenshot 1](https://raw.githubusercontent.com/TheMisir/flutter-network-logger/master/screenshots/1.jpg)|![Screenshot 2](https://raw.githubusercontent.com/TheMisir/flutter-network-logger/master/screenshots/2.jpg)|
|-|-|
|Log feed|Log details|

## 🚀 Getting Started!

You are 3 steps ahead from viewing http traffic logs on well designed GUI.

### 1. Install `network_logger`.
Check [this guide](https://pub.dev/packages/network_logger/install) to install **network_logger** to your flutter project.

### 2. Add `DioNetworkLogger` interceptor to dio client.

**network_logger** comes with [Dio](https://pub.dev/packages/dio) interceptor which will intercept traffic from Dio client. Other package implementations coming soon.

```dart
var dio = Dio();
dio.interceptors.add(DioNetworkLogger());
```

### 3. Attach network logger overlay button to UI.

The easiest way to access Network Logger UI is using `NetworkLoggerOverlay` which will display floating action button over all screens. You can also implement custom scenarios to open UI with different actions.

```dart
@override
void initState() {
  NetworkLoggerOverlay.attachTo(context);
  super.initState();
}
```