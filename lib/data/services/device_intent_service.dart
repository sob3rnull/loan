import 'dart:async';

import 'package:flutter/services.dart';

class DeviceIntentService {
  DeviceIntentService(this.channelName) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final String channelName;
  final StreamController<String> _incomingFileController =
      StreamController<String>.broadcast();

  late final MethodChannel _channel = MethodChannel(channelName);

  Stream<String> get incomingFiles => _incomingFileController.stream;

  Future<String?> getInitialFilePath() async {
    return _channel.invokeMethod<String>('getInitialFilePath');
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onIncomingFile') {
      return;
    }

    final path = call.arguments as String?;
    if (path == null || path.isEmpty) {
      return;
    }

    _incomingFileController.add(path);
  }

  void dispose() {
    _incomingFileController.close();
  }
}
