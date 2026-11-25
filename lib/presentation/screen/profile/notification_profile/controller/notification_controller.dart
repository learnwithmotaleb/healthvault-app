import 'dart:async';

import 'package:get/get.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../data/models/json.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../../service/notification_router.dart';
import '../../../../../service/socket_service.dart';

class NotificationController extends GetxController {
  final _api = ApiClient();
  final items = <NotificationModel>[].obs;
  final unreadOnly = false.obs;
  final type = ''.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  int _page = 1;
  bool _hasMore = false;
  StreamSubscription? _sub;

  static const types = ['APPOINTMENT', 'MEDICATION', 'INSURANCE', 'DOCUMENT', 'SUPPORT', 'SOS', 'PROVIDER', 'GENERAL'];

  @override
  void onInit() {
    super.onInit();
    fetch();
    _sub = RealtimeService.to.notifications.listen((n) {
      if (!unreadOnly.value || !n.isRead) {
        if (type.value.isEmpty || type.value == n.type) items.insert(0, n);
      }
    });
  }

  Map<String, dynamic> _q(int page) => {
        "page": page,
        "limit": 20,
        if (unreadOnly.value) "isRead": false,
        "type": type.value,
      };

  Future<void> fetch() async {
    _page = 1;
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.getAllNotification, query: _q(1));
    isLoading.value = false;
    if (res.isOk) {
      final p = Paged.parse(res.data, NotificationModel.fromJson);
      items.assignAll(p.items);
      _hasMore = p.hasMore;
      final unread = J.integer(p.meta['unreadCount']);
      if (unread != null) RealtimeService.to.unreadCount.value = unread;
    } else {
      error.value = res.message;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value) return;
    isLoadingMore.value = true;
    final res = await _api.get(url: ApiUrl.getAllNotification, query: _q(_page + 1));
    isLoadingMore.value = false;
    if (res.isOk) {
      final p = Paged.parse(res.data, NotificationModel.fromJson);
      _page++;
      items.addAll(p.items);
      _hasMore = p.hasMore;
    }
  }

  void setUnreadOnly(bool v) {
    unreadOnly.value = v;
    fetch();
  }

  void setType(String v) {
    type.value = v;
    fetch();
  }

  Future<void> open(NotificationModel n) async {
    if (!n.isRead) {
      n.isRead = true;
      items.refresh();
      final rt = RealtimeService.to;
      if (rt.unreadCount.value > 0) rt.unreadCount.value--;
      _api.patch(url: ApiUrl.readNotification(n.id));
    }
    await NotificationRouter.open(n.data, title: n.title, message: n.message);
  }

  Future<void> markAllRead() async {
    final res = await _api.patch(url: ApiUrl.readAllNotifications);
    if (res.isOk) {
      for (final n in items) {
        n.isRead = true;
      }
      items.refresh();
      RealtimeService.to.unreadCount.value = 0;
      if (unreadOnly.value) fetch();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  Future<void> remove(NotificationModel n) async {
    items.remove(n);
    final res = await _api.delete(url: ApiUrl.removeNotification(n.id));
    if (!res.isOk) {
      AppSnackBar.fail(res.message);
      fetch();
    } else if (!n.isRead && RealtimeService.to.unreadCount.value > 0) {
      RealtimeService.to.unreadCount.value--;
    }
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
