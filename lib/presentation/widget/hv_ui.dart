import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../service/api_url.dart';
import '../../utils/app_colors/app_colors.dart';
import '../../utils/app_text_style/app_text_style.dart';

// ============================================================ formatting
class Fmt {
  /// Current app language for month / weekday names ("en" or "el").
  static String get lang => Get.locale?.languageCode == 'el' ? 'el' : 'en';
  static DateFormat _f(String p) => DateFormat(p, lang);

  static String date(DateTime? d) => d == null ? '-' : _f('dd MMM yyyy').format(d);
  static String dateTime(DateTime? d) => d == null ? '-' : _f(lang == 'el' ? 'dd MMM yyyy, HH:mm' : 'dd MMM yyyy, hh:mm a').format(d);
  static String time(DateTime? d) => d == null ? '-' : _f(lang == 'el' ? 'HH:mm' : 'hh:mm a').format(d);
  static String dayMonth(DateTime? d) => d == null ? '-' : _f('dd MMM').format(d);
  static String weekdayShort(DateTime d) => _f('EEE').format(d);
  static String monthShort(DateTime d) => _f('MMM').format(d);
  static String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String ago(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'now'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return date(d);
  }

  /// "PENDING_X" → "Pending x"
  static String enumLabel(String v) {
    if (v.isEmpty) return v;
    final s = v.replaceAll('_', ' ').toLowerCase();
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ============================================================ colors per status
Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIRMED':
    case 'APPROVED':
    case 'TAKEN':
    case 'RESOLVED':
    case 'OPEN':
      return const Color(0xFF2E7D32);
    case 'COMPLETED':
      return AppColors.loginLogoRadiusColor;
    case 'CANCELLED':
    case 'REJECTED':
    case 'MISSED':
    case 'ACTIVE_SOS':
      return AppColors.emergencyColor;
    case 'SKIPPED':
    case 'CLOSED':
      return AppColors.greyColor;
    case 'UPCOMING':
      return AppColors.primaryColor;
    case 'PENDING':
    default:
      return const Color(0xFFE09B00);
  }
}

// ============================================================ widgets
class HVCardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color color;
  final Color? borderColor;
  final double radius;

  const HVCardBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(vertical: 6),
    this.onTap,
    this.color = AppColors.whiteColor,
    this.borderColor,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  final String? label;
  final Color? color;
  const StatusChip(this.status, {super.key, this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label ?? Fmt.enumLabel(status).tr,
        style: AppTextStyles.body.copyWith(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.title.copyWith(fontSize: 16, fontWeight: FontWeight.w600))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!, style: AppTextStyles.body.copyWith(color: AppColors.primaryColor)),
            ),
        ],
      ),
    );
  }
}

class InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const InfoLine(this.icon, this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.primaryColor),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 13, color: AppColors.labelColor))),
        ],
      ),
    );
  }
}

class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  const KeyValueRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.hintColor, fontSize: 13)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: AppTextStyles.body.copyWith(fontSize: 13))),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyView({super.key, this.icon = Icons.inbox_outlined, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: AppColors.primaryColor.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 16)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(color: AppColors.hintColor)),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => EmptyView(
        icon: Icons.cloud_off_outlined,
        title: message,
        action: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text('Retry'.tr),
        ),
      );
}

/// Loading / error / empty / content wrapper with pull-to-refresh.
class AsyncList extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool isEmpty;
  final Widget empty;
  final Future<void> Function() onRefresh;
  final Widget child;

  const AsyncList({
    super.key,
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.empty,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
    }
    if (error != null && isEmpty) {
      return ErrorView(message: error!, onRetry: onRefresh);
    }
    return RefreshIndicator(
      color: AppColors.primaryColor,
      onRefresh: onRefresh,
      child: isEmpty
          ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              empty,
            ])
          : child,
    );
  }
}

/// Image that adds the auth header for private `uploads/private/...` files.
class ApiImage extends StatelessWidget {
  final String? value;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? radius;
  final Widget? placeholder;

  const ApiImage(this.value, {super.key, this.width, this.height, this.fit = BoxFit.cover, this.radius, this.placeholder});

  @override
  Widget build(BuildContext context) {
    final url = ApiUrl.fileUrl(value);
    final fallback = placeholder ??
        Container(
          width: width,
          height: height,
          color: AppColors.bottomNavigationColor,
          child: const Icon(Icons.image_outlined, color: AppColors.primaryColor),
        );
    if (url.isEmpty) return ClipRRect(borderRadius: radius ?? BorderRadius.zero, child: fallback);
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.zero,
      child: Image.network(
        url,
        headers: ApiUrl.fileHeaders(value),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder: (c, child, p) => p == null
            ? child
            : SizedBox(
                width: width,
                height: height,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor)),
              ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final String? image;
  final String name;
  final double radius;
  const Avatar({super.key, this.image, required this.name, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    final url = ApiUrl.fileUrl(image);
    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.15),
      foregroundImage: url.isNotEmpty ? NetworkImage(url, headers: ApiUrl.fileHeaders(image)) : null,
      child: Text(letter,
          style: AppTextStyles.title.copyWith(color: AppColors.primaryColor, fontSize: radius * 0.8)),
    );
  }
}

/// Horizontal choice chips (filters / tabs).
class ChoiceBar extends StatelessWidget {
  final List<String> values;
  final List<String>? labels;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  const ChoiceBar({
    super.key,
    required this.values,
    this.labels,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: List.generate(values.length, (i) {
          final v = values[i];
          final isSel = v == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels?[i] ?? Fmt.enumLabel(v).tr),
              selected: isSel,
              showCheckmark: false,
              selectedColor: AppColors.primaryColor,
              backgroundColor: AppColors.bottomNavigationColor,
              side: BorderSide(color: isSel ? AppColors.primaryColor : AppColors.primaryColor.withValues(alpha: 0.3)),
              labelStyle: AppTextStyles.body.copyWith(
                color: isSel ? AppColors.whiteColor : AppColors.primaryColor,
                fontSize: 13,
              ),
              onSelected: (_) => onSelected(v),
            ),
          );
        }),
      ),
    );
  }
}

/// Labeled input in the app's outlined style.
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final bool obscure;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryColor),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: obscure ? 1 : maxLines,
            obscureText: obscure,
            readOnly: readOnly,
            onTap: onTap,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.hint,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              suffixIcon: suffixIcon,
              border: border,
              enabledBorder: border.copyWith(borderSide: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5))),
              focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5)),
              errorBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.emergencyColor)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown in the same style as [LabeledField].
class LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? hint;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<T>(
            initialValue: items.contains(value) ? value : null,
            isExpanded: true,
            hint: hint != null ? Text(hint!, style: AppTextStyles.hint) : null,
            items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(itemLabel(e)))).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: border,
              enabledBorder: border,
              focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  final IconData? icon;
  final bool outlined;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color = AppColors.primaryColor,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 20, color: outlined ? color : Colors.white), const SizedBox(width: 8)],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button.copyWith(color: outlined ? color : Colors.white)),
            ),
          ]);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: loading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: child,
            )
          : ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: child,
            ),
    );
  }
}

// ============================================================ dialogs & pickers
class Dialogs {
  static Future<bool> confirm({
    required String title,
    required String message,
    String? confirmText,
    bool destructive = false,
  }) async {
    final r = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title, style: AppTextStyles.title.copyWith(fontSize: 17)),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('Cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(confirmText ?? 'Yes'.tr,
                style: TextStyle(color: destructive ? AppColors.emergencyColor : AppColors.primaryColor)),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  /// Text input dialog; returns null if cancelled.
  static Future<String?> input({
    required String title,
    String? hint,
    String? initial,
    String? confirmText,
    int maxLines = 3,
    bool required = false,
  }) async {
    final c = TextEditingController(text: initial);
    final r = await Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title, style: AppTextStyles.title.copyWith(fontSize: 17)),
        content: TextField(
          controller: c,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel'.tr)),
          TextButton(
            onPressed: () {
              if (required && c.text.trim().isEmpty) return;
              Get.back(result: c.text.trim());
            },
            child: Text(confirmText ?? 'OK'.tr),
          ),
        ],
      ),
    );
    return r;
  }

  static Future<DateTime?> pickDate({DateTime? initial, DateTime? first, DateTime? last}) {
    final now = DateTime.now();
    return showDatePicker(
      context: Get.context!,
      initialDate: initial ?? now,
      firstDate: first ?? DateTime(1900),
      lastDate: last ?? DateTime(now.year + 20),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryColor)),
        child: child!,
      ),
    );
  }

  static Future<TimeOfDay?> pickTime({TimeOfDay? initial}) {
    return showTimePicker(
      context: Get.context!,
      initialTime: initial ?? TimeOfDay.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryColor)),
        child: child!,
      ),
    );
  }
}

class FilePick {
  static const maxBytes = 10 * 1024 * 1024;

  static bool _tooBig(String path) {
    final f = File(path);
    if (f.existsSync() && f.lengthSync() > maxBytes) {
      Get.snackbar('Health Vault', 'File is too large (max 10MB)',
          backgroundColor: AppColors.emergencyColor, colorText: Colors.white);
      return true;
    }
    return false;
  }

  /// Image from gallery or camera.
  static Future<File?> image({ImageSource source = ImageSource.gallery}) async {
    final x = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 2000);
    if (x == null || _tooBig(x.path)) return null;
    return File(x.path);
  }

  /// Image or PDF (jpg, png, webp, pdf).
  static Future<List<File>> documents({bool multiple = false, int max = 5}) async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    final files = res.where((f) => f.path != null).map((f) => File(f.path!)).where((f) => !_tooBig(f.path)).toList();
    if (!multiple && files.length > 1) return [files.first];
    return files.take(max).toList();
  }

  /// Bottom sheet: Camera / Gallery / File (pdf).
  static Future<List<File>> chooseSource({bool allowPdf = true, bool multiple = false}) async {
    final choice = await Get.bottomSheet<String>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Wrap(children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primaryColor),
              title: Text('Camera'.tr),
              onTap: () => Get.back(result: 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryColor),
              title: Text('Gallery'.tr),
              onTap: () => Get.back(result: 'gallery'),
            ),
            if (allowPdf)
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryColor),
                title: Text('Files (PDF / image)'.tr),
                onTap: () => Get.back(result: 'file'),
              ),
          ]),
        ),
      ),
    );
    switch (choice) {
      case 'camera':
        final f = await image(source: ImageSource.camera);
        return f == null ? [] : [f];
      case 'gallery':
        final f = await image();
        return f == null ? [] : [f];
      case 'file':
        return documents(multiple: multiple);
    }
    return [];
  }
}

/// A selected local file preview tile.
class LocalFileTile extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const LocalFileTile({super.key, required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isPdf = file.path.toLowerCase().endsWith('.pdf');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: isPdf
              ? Container(
                  width: 48,
                  height: 48,
                  color: AppColors.bottomNavigationColor,
                  child: const Icon(Icons.picture_as_pdf, color: AppColors.emergencyColor),
                )
              : Image.file(file, width: 48, height: 48, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(file.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.body),
        ),
        IconButton(onPressed: onRemove, icon: const Icon(Icons.close, color: AppColors.emergencyColor)),
      ]),
    );
  }
}

// ============================================================ validators
class V {
  static String? required(String? v) => (v == null || v.trim().isEmpty) ? 'This field is required'.tr : null;

  static String? Function(String?) numberIn(num min, num max, {bool optional = true}) => (v) {
        if (v == null || v.trim().isEmpty) return optional ? null : 'This field is required'.tr;
        final n = num.tryParse(v.trim());
        if (n == null) return 'Enter a number'.tr;
        if (n < min || n > max) return '${'Must be between'.tr} $min–$max';
        return null;
      };

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required'.tr;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? null : 'Invalid email format'.tr;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'This field is required'.tr;
    if (v.length < 8) return 'Password must be at least 8 characters'.tr;
    return null;
  }
}

/// Split "a, b ,c" → ["a","b","c"].
List<String> splitCsv(String s) => s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
