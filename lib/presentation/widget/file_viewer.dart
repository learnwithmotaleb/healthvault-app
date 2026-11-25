import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../helper/tost_message/show_snackbar.dart';
import '../../service/api_service.dart';
import '../../service/api_url.dart';
import 'hv_ui.dart';

/// Opens a file value returned by the API (public URL or private path).
class FileViewer {
  static bool _isPdf(String v) => v.toLowerCase().split('?').first.endsWith('.pdf');

  static Future<void> open(String value, {String? title, String? mimeType}) async {
    final isPdf = _isPdf(value) || (mimeType ?? '').contains('pdf');
    if (!isPdf) {
      Get.to(() => _ImageViewer(value: value, title: title));
      return;
    }
    final file = await download(value);
    if (file == null) return;
    final r = await OpenFilex.open(file.path, type: 'application/pdf');
    if (r.type != ResultType.done) {
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]));
    }
  }

  /// Download to the temp folder (with auth header when needed).
  static Future<File?> download(String value) async {
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    try {
      final res = await ApiClient().download(ApiUrl.fileUrl(value));
      if (res == null || res.statusCode != 200) {
        AppSnackBar.fail(res?.statusCode == 403 ? "You don't have access to this file" : "Could not open the file");
        return null;
      }
      final dir = await getTemporaryDirectory();
      final name = value.split('/').last.split('?').first;
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(res.bodyBytes);
      return file;
    } finally {
      if (Get.isDialogOpen ?? false) Get.back();
    }
  }

  static Future<void> share(String value) async {
    final f = await download(value);
    if (f != null) await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
  }
}

class _ImageViewer extends StatelessWidget {
  final String value;
  final String? title;
  const _ImageViewer({required this.value, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title ?? ''),
        actions: [
          IconButton(onPressed: () => FileViewer.share(value), icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: ApiImage(value, fit: BoxFit.contain, width: double.infinity)),
      ),
    );
  }
}
