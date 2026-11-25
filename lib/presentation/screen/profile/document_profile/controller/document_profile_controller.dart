import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../data/models/app_models.dart';
import '../../../../../data/models/json.dart';
import '../../../../../helper/tost_message/show_snackbar.dart';
import '../../../../../service/api_service.dart';
import '../../../../../service/api_url.dart';
import '../../../../widget/hv_ui.dart';

const documentCategories = ['PRESCRIPTION', 'LAB_RESULT', 'IMAGING', 'VACCINATION', 'REPORT', 'OTHER'];

IconData categoryIcon(String c) {
  switch (c) {
    case 'PRESCRIPTION':
      return Icons.receipt_long_outlined;
    case 'LAB_RESULT':
      return Icons.biotech_outlined;
    case 'IMAGING':
      return Icons.image_search_outlined;
    case 'VACCINATION':
      return Icons.vaccines_outlined;
    case 'REPORT':
      return Icons.description_outlined;
    default:
      return Icons.folder_outlined;
  }
}

/// GET /medicalDocument/my (+ tags)
class DocumentListController extends GetxController {
  final _api = ApiClient();
  final docs = <MedicalDocumentModel>[].obs;
  final tags = <(String, int)>[].obs;
  final search = TextEditingController();
  final category = ''.obs;
  final forWhom = ''.obs;
  final tag = ''.obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  int _page = 1;
  bool _hasMore = false;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetch();
    search.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 450), fetch);
    });
  }

  Map<String, dynamic> _q(int page) => {
        "page": page,
        "limit": 20,
        "searchTerm": search.text.trim(),
        "category": category.value,
        "forWhom": forWhom.value,
        "tag": tag.value,
      };

  Future<void> fetch() async {
    _page = 1;
    isLoading.value = true;
    error.value = null;
    final res = await _api.get(url: ApiUrl.myDocuments, query: _q(1));
    isLoading.value = false;
    if (res.isOk) {
      final p = Paged.parse(res.data, MedicalDocumentModel.fromJson);
      docs.assignAll(p.items);
      _hasMore = p.hasMore;
    } else {
      error.value = res.message;
    }
    _loadTags();
  }

  Future<void> loadMore() async {
    if (!_hasMore || isLoadingMore.value) return;
    isLoadingMore.value = true;
    final res = await _api.get(url: ApiUrl.myDocuments, query: _q(_page + 1));
    isLoadingMore.value = false;
    if (res.isOk) {
      final p = Paged.parse(res.data, MedicalDocumentModel.fromJson);
      _page++;
      docs.addAll(p.items);
      _hasMore = p.hasMore;
    }
  }

  Future<void> _loadTags() async {
    final res = await _api.get(url: ApiUrl.myDocumentTags);
    if (res.isOk && res.data is List) {
      tags.assignAll((res.data as List)
          .whereType<Map>()
          .map((m) => (J.s(m['tag']), J.integer(m['count']) ?? 0))
          .where((t) => t.$1.isNotEmpty));
    }
  }

  void setCategory(String v) {
    category.value = v;
    fetch();
  }

  void setForWhom(String v) {
    forWhom.value = v;
    fetch();
  }

  void setTag(String v) {
    tag.value = tag.value == v ? '' : v;
    fetch();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    search.dispose();
    super.onClose();
  }
}

/// POST /medicalDocument (multipart: data + document ×5)
class DocumentUploadController extends GetxController {
  final _api = ApiClient();
  final formKey = GlobalKey<FormState>();
  final title = TextEditingController();
  final tagsText = TextEditingController();
  final familyName = TextEditingController();
  final category = 'OTHER'.obs;
  final forWhom = 'SELF'.obs;
  final documentDate = Rxn<DateTime>();
  final files = <File>[].obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['forWhom'] is String && (args['forWhom'] as String).isNotEmpty) {
      forWhom.value = args['forWhom'];
    }
  }

  Future<void> addFiles() async {
    if (files.length >= 5) return AppSnackBar.info("Maximum 5 files per upload");
    final picked = await FilePick.chooseSource(multiple: true);
    files.addAll(picked.take(5 - files.length));
  }

  List<String> get tags =>
      splitCsv(tagsText.text).map((t) => t.toLowerCase()).where((t) => t.length <= 30).toSet().take(15).toList();

  Future<void> upload() async {
    if (files.isEmpty) return AppSnackBar.fail("Add at least one file");
    if (forWhom.value == 'FAMILY' && familyName.text.trim().isEmpty) {
      return AppSnackBar.fail("Enter the family member's name");
    }
    final data = <String, dynamic>{
      if (title.text.trim().isNotEmpty) "title": title.text.trim(),
      "category": category.value,
      if (tags.isNotEmpty) "tags": tags,
      "forWhom": forWhom.value,
      if (forWhom.value == 'FAMILY') "familyMemberName": familyName.text.trim(),
      if (documentDate.value != null) "documentDate": Fmt.apiDate(documentDate.value!),
    };
    isSaving.value = true;
    final res = await _api.sendForm(
      url: ApiUrl.uploadDocument,
      data: data,
      files: files.map((f) => MultipartFileData(key: "document", path: f.path)).toList(),
    );
    isSaving.value = false;
    if (res.isOk) {
      AppSnackBar.success(files.length == 1 ? "Document uploaded" : "${files.length} ${'documents uploaded'.tr}");
      if (Get.isRegistered<DocumentListController>()) Get.find<DocumentListController>().fetch();
      Get.back(result: true);
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  @override
  void onClose() {
    title.dispose();
    tagsText.dispose();
    familyName.dispose();
    super.onClose();
  }
}

/// GET/PATCH/DELETE /medicalDocument/:id + share
class DocumentDetailsController extends GetxController {
  final _api = ApiClient();
  final doc = Rxn<MedicalDocumentModel>();
  final isLoading = false.obs;
  final isWorking = false.obs;
  final shareUrl = RxnString();
  final shareExpires = Rxn<DateTime>();
  late String id;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is MedicalDocumentModel) {
      doc.value = args;
      id = args.id;
    } else {
      id = args is Map ? (args['id'] ?? args['documentId'] ?? '').toString() : '';
    }
    load();
  }

  Future<void> load() async {
    if (id.isEmpty) return;
    isLoading.value = true;
    final res = await _api.get(url: ApiUrl.myDocument(id));
    isLoading.value = false;
    if (res.isOk && res.data is Map) doc.value = MedicalDocumentModel.fromJson(J.map(res.data));
  }

  void _refreshList() {
    if (Get.isRegistered<DocumentListController>()) Get.find<DocumentListController>().fetch();
  }

  Future<void> updateMeta(Map<String, dynamic> body) async {
    isWorking.value = true;
    final res = await _api.patch(url: ApiUrl.document(id), body: body);
    isWorking.value = false;
    if (res.isOk) {
      AppSnackBar.success("Document updated");
      await load();
      _refreshList();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  Future<void> createShare(int hours) async {
    isWorking.value = true;
    final res = await _api.post(url: ApiUrl.shareDocument(id), body: {"expiresInHours": hours});
    isWorking.value = false;
    if (res.isOk) {
      final d = J.map(res.data);
      shareUrl.value = J.str(d['shareUrl']);
      shareExpires.value = J.date(d['expiresAt']);
      await load();
      _refreshList();
      if (shareUrl.value != null) {
        await SharePlus.instance.share(ShareParams(
          text: "${doc.value?.title ?? 'Medical document'}: ${shareUrl.value}",
          subject: doc.value?.title,
        ));
      }
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  Future<void> copyShare() async {
    if (shareUrl.value == null) return;
    await Clipboard.setData(ClipboardData(text: shareUrl.value!));
    AppSnackBar.success("Link copied");
  }

  Future<void> stopShare() async {
    isWorking.value = true;
    final res = await _api.delete(url: ApiUrl.shareDocument(id));
    isWorking.value = false;
    if (res.isOk) {
      shareUrl.value = null;
      shareExpires.value = null;
      AppSnackBar.success("Sharing stopped");
      await load();
      _refreshList();
    } else {
      AppSnackBar.fail(res.message);
    }
  }

  Future<void> deleteDoc() async {
    if (!await Dialogs.confirm(title: 'Delete document'.tr, message: 'The file will be deleted permanently.'.tr, destructive: true)) {
      return;
    }
    isWorking.value = true;
    final res = await _api.delete(url: ApiUrl.document(id));
    isWorking.value = false;
    if (res.isOk) {
      AppSnackBar.success("Document deleted");
      _refreshList();
      Get.back();
    } else {
      AppSnackBar.fail(res.message);
    }
  }
}
