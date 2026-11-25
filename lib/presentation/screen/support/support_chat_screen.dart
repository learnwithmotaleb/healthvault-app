import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/app_models.dart';
import '../../../data/models/json.dart';
import '../../../helper/tost_message/show_snackbar.dart';
import '../../../service/api_service.dart';
import '../../../service/api_url.dart';
import '../../../service/socket_service.dart';
import '../../../utils/app_colors/app_colors.dart';
import '../../../utils/app_text_style/app_text_style.dart';
import '../../widget/custom_appbar.dart';
import '../../widget/hv_ui.dart';

/// GET /support/my-conversation · POST /support/messages · socket `support-message`
class SupportChatController extends GetxController {
  final _api = ApiClient();
  final messages = <SupportMessage>[].obs; // oldest → newest
  final status = 'OPEN'.obs;
  final isLoading = false.obs;
  final isLoadingOlder = false.obs;
  final isSending = false.obs;
  final hasMore = false.obs;
  final error = RxnString();
  final input = TextEditingController();
  final scroll = ScrollController();
  final List<StreamSubscription> _subs = [];

  @override
  void onInit() {
    super.onInit();
    load();
    RealtimeService.to.connect();
    _subs.add(RealtimeService.to.supportMessages.listen((d) {
      final m = SupportMessage.fromJson(J.map(d['message']));
      if (m.id.isNotEmpty && messages.every((e) => e.id != m.id)) {
        messages.add(m);
        _toBottom();
      }
      final conv = J.map(d['conversation']);
      if (conv['status'] != null) status.value = J.s(conv['status']).toUpperCase();
    }));
    _subs.add(RealtimeService.to.supportStatus.listen((s) => status.value = s.toUpperCase()));
    scroll.addListener(() {
      if (scroll.position.pixels <= 60) loadOlder();
    });
  }

  void _parse(dynamic data, {bool older = false}) {
    final d = J.map(data);
    final conv = J.map(d['conversation']);
    if (conv['status'] != null) status.value = J.s(conv['status']).toUpperCase();
    final list = J.list(d['messages'], SupportMessage.fromJson).reversed.toList();
    hasMore.value = J.b(d['hasMore']);
    if (older) {
      messages.insertAll(0, list.where((m) => messages.every((e) => e.id != m.id)));
    } else {
      messages.assignAll(list);
    }
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.supportConversation, query: {"limit": 30});
    isLoading.value = false;
    if (res.isOk) {
      _parse(res.data);
      _toBottom(jump: true);
    } else {
      error.value = res.message;
    }
  }

  Future<void> loadOlder() async {
    if (!hasMore.value || isLoadingOlder.value || messages.isEmpty) return;
    isLoadingOlder.value = true;
    final res = await _api.get(
      url: ApiUrl.supportConversation,
      query: {"limit": 30, "before": messages.first.createdAtRaw},
    );
    isLoadingOlder.value = false;
    if (res.isOk) _parse(res.data, older: true);
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    if (text.length > 2000) return AppSnackBar.fail("Message is too long (max 2000)");
    isSending.value = true;
    final res = await _api.post(url: ApiUrl.supportMessages, body: {"text": text});
    isSending.value = false;
    if (res.isOk) {
      input.clear();
      if (res.data is Map) {
        final m = SupportMessage.fromJson(J.map(res.data));
        if (messages.every((e) => e.id != m.id)) messages.add(m);
      }
      status.value = 'OPEN';
      _toBottom();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  void _toBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      final max = scroll.position.maxScrollExtent;
      jump ? scroll.jumpTo(max) : scroll.animateTo(max, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    input.dispose();
    scroll.dispose();
    super.onClose();
  }
}

class SupportChatScreen extends StatelessWidget {
  const SupportChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SupportChatController());
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFC),
      appBar: CommonAppBar(title: 'Support'.tr, actions: [
        Obx(() => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: StatusChip(c.status.value, label: Fmt.enumLabel(c.status.value).tr)),
            )),
      ]),
      body: Column(children: [
        Expanded(
          child: Obx(() {
            if (c.isLoading.value && c.messages.isEmpty) return const Center(child: CircularProgressIndicator());
            if (c.error.value != null && c.messages.isEmpty) return ErrorView(message: c.error.value!, onRetry: c.load);
            if (c.messages.isEmpty) {
              return EmptyView(
                icon: Icons.support_agent,
                title: 'How can we help?'.tr,
                subtitle: 'Send a message and our support team will reply here.'.tr,
              );
            }
            return ListView.builder(
              controller: c.scroll,
              padding: const EdgeInsets.all(12),
              itemCount: c.messages.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Obx(() => c.isLoadingOlder.value
                      ? const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      : const SizedBox.shrink());
                }
                final m = c.messages[i - 1];
                final mine = !m.isFromSupport;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: mine ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(mine ? 14 : 2),
                        bottomRight: Radius.circular(mine ? 2 : 14),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (!mine)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Support team'.tr,
                              style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.primaryColor, fontWeight: FontWeight.w600)),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(m.text, style: AppTextStyles.body.copyWith(color: mine ? Colors.white : Colors.black)),
                      ),
                      const SizedBox(height: 2),
                      Text(Fmt.time(m.createdAt),
                          style: AppTextStyles.body.copyWith(fontSize: 10, color: mine ? Colors.white70 : AppColors.hintColor)),
                    ]),
                  ),
                );
              },
            );
          }),
        ),
        Obx(() => c.status.value == 'CLOSED'
            ? Container(
                width: double.infinity,
                color: Colors.grey.shade200,
                padding: const EdgeInsets.all(8),
                child: Text('This chat was closed. Send a message to reopen it.'.tr,
                    textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 12)),
              )
            : const SizedBox.shrink()),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            color: Colors.white,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: c.input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type a message'.tr,
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.bottomNavigationColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Obx(() => IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primaryColor),
                    onPressed: c.isSending.value ? null : c.send,
                    icon: c.isSending.value
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, color: Colors.white),
                  )),
            ]),
          ),
        ),
      ]),
    );
  }
}
