import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../data/models/app_models.dart';
import '../data/models/json.dart';
import '../helper/local_db/local_db.dart';
import 'api_service.dart';
import 'api_url.dart';

/// Socket.io connection for live notifications and support chat.
///
/// Events (server → app): `notification`, `notification-count`,
/// `support-message`, `support-status`.
class RealtimeService extends GetxService {
  static RealtimeService get to =>
      Get.isRegistered<RealtimeService>() ? Get.find<RealtimeService>() : Get.put(RealtimeService(), permanent: true);

  io.Socket? _socket;

  final RxInt unreadCount = 0.obs;
  final RxBool connected = false.obs;

  final _notifications = StreamController<NotificationModel>.broadcast();
  final _supportMessages = StreamController<Map<String, dynamic>>.broadcast();
  final _supportStatus = StreamController<String>.broadcast();

  Stream<NotificationModel> get notifications => _notifications.stream;
  Stream<Map<String, dynamic>> get supportMessages => _supportMessages.stream;
  Stream<String> get supportStatus => _supportStatus.stream;

  void connect() {
    final token = SharePrefsHelper.getToken();
    if (token == null || token.isEmpty) return;
    if (_socket != null) {
      if (!(_socket!.connected)) _socket!.connect();
      return;
    }

    _socket = io.io(
      ApiUrl.mainDomain,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        connected.value = true;
        debugPrint('🔌 Socket connected');
      })
      ..onDisconnect((_) {
        connected.value = false;
        debugPrint('🔌 Socket disconnected');
      })
      ..onConnectError((e) async {
        debugPrint('🔌 Socket connect_error: $e');
        if (e.toString().contains('Unauthorized')) {
          final ok = await ApiClient.refreshAccessToken();
          if (ok) reconnect();
        }
      })
      ..on('notification', (data) {
        try {
          final n = NotificationModel.fromJson(J.map(data));
          unreadCount.value = unreadCount.value + 1;
          _notifications.add(n);
        } catch (_) {}
      })
      ..on('notification-count', (data) {
        unreadCount.value = J.integer(J.map(data)['unreadCount']) ?? 0;
      })
      ..on('support-message', (data) => _supportMessages.add(J.map(data)))
      ..on('support-status', (data) => _supportStatus.add(J.s(J.map(data)['status'])));

    _socket!.connect();
    refreshUnreadCount();
  }

  void reconnect() {
    disconnect();
    connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
    connected.value = false;
    unreadCount.value = 0;
  }

  Future<void> refreshUnreadCount() async {
    final res = await ApiClient().get(url: ApiUrl.unreadCount);
    if (res.isOk) unreadCount.value = J.integer(J.map(res.data)['unreadCount']) ?? 0;
  }

  @override
  void onClose() {
    disconnect();
    _notifications.close();
    _supportMessages.close();
    _supportStatus.close();
    super.onClose();
  }
}

/// Kept for older imports.
class SocketApi {
  static void init() => RealtimeService.to.connect();
}
