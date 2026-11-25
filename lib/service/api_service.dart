import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:healthvault/service/api_url.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';

import '../helper/local_db/local_db.dart';
import '../helper/no_internet/controller/no_internet_controller.dart';
import 'session_service.dart';

final log = Logger(printer: PrettyPrinter(methodCount: 0));

typedef ApiResult = Response;

/// Convenience accessors on every API response.
extension ApiResponseX on Response {
  /// 2xx and `success != false`.
  bool get isOk {
    final code = statusCode ?? 0;
    if (code < 200 || code >= 300) return false;
    final b = body;
    if (b is Map && b['success'] == false) return false;
    return true;
  }

  /// `data` field of the standard envelope.
  dynamic get data => body is Map ? body['data'] : null;

  /// Human message – API `message`, or a transport error.
  String get message {
    final b = body;
    if (b is Map && b['message'] is String && (b['message'] as String).isNotEmpty) {
      return b['message'];
    }
    return statusText ?? 'Something went wrong';
  }

  /// List of `{path, message}` validation errors.
  List<Map<String, dynamic>> get fieldErrors {
    final b = body;
    if (b is Map && b['error'] is List) {
      return (b['error'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }
}

class ApiClient {
  static const defaultTimeout = Duration(seconds: 30);
  static const uploadTimeout = Duration(seconds: 120);

  /// One refresh at a time, shared by concurrent 401s.
  static Future<bool>? _refreshing;

  static Map<String, String> _authHeader() {
    final token = SharePrefsHelper.getToken();
    if (token == null || token.isEmpty) return {};
    final value = token.startsWith('Bearer ') ? token : 'Bearer $token';
    return {"Authorization": value};
  }

  Future<Map<String, String>> _headers({
    bool json = true,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) async {
    final headers = <String, String>{
      if (json) "Content-Type": "application/json",
      "Accept": "application/json",
      if (isToken) ..._authHeader(),
    };
    if (customHeaders != null) {
      customHeaders.forEach((k, v) {
        // Older callers passed the raw token: normalise to Bearer.
        if (k.toLowerCase() == 'authorization') {
          if (v.isEmpty) return;
          headers['Authorization'] = v.startsWith('Bearer ') ? v : 'Bearer $v';
        } else {
          headers[k] = v;
        }
      });
    }
    return headers;
  }

  static String withQuery(String url, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return url;
    final q = <String, String>{};
    query.forEach((k, v) {
      if (v == null) return;
      final s = v is List ? v.join(',') : v.toString();
      if (s.isEmpty) return;
      q[k] = s;
    });
    if (q.isEmpty) return url;
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: {...uri.queryParameters, ...q}).toString();
  }

  /// Auth endpoints answer 401 for wrong credentials – never refresh on those.
  static bool _isAuthEndpoint(String url) =>
      url.contains('/auth/login') ||
      url.contains('/auth/refresh-token') ||
      url.contains('/auth/verify') ||
      url.contains('/auth/reset-password') ||
      url.contains('/auth/forgot-password') ||
      url.contains('/auth/resend-otp') ||
      url.contains('/user/register');

  // ---------------------------------------------------------------- core
  Future<ApiResult> safeRequest(
    Future<http.Response> Function() requestFn, {
    required String url,
    String method = "GET",
    bool checkInternet = true,
    Duration timeout = defaultTimeout,
  }) async {
    try {
      _logRequest(url, method);

      if (checkInternet && Get.isRegistered<InternetController>()) {
        final c = Get.find<InternetController>();
        if (!c.isConnected.value) return _handleException("No internet connection!", 503);
      }

      final hadToken = (SharePrefsHelper.getToken() ?? '').isNotEmpty;
      http.Response response = await requestFn().timeout(timeout);

      if (response.statusCode == 401 && hadToken && !_isAuthEndpoint(url)) {
        final refreshed = await refreshAccessToken();
        if (refreshed) {
          response = await requestFn().timeout(timeout);
        } else {
          await SessionService.forceLogout(message: "Session expired. Please login again.");
          return _handleResponse(response);
        }
      }

      if (response.statusCode == 403 && !_isAuthEndpoint(url)) {
        final r = _handleResponse(response);
        if (r.message.toLowerCase().contains('blocked')) {
          await SessionService.forceLogout(message: r.message);
        }
        return r;
      }

      if (Get.isRegistered<InternetController>()) {
        Get.find<InternetController>().setConnected();
      }
      return _handleResponse(response);
    } on SocketException {
      return _handleException("Cannot reach the server. Check your connection.", 503);
    } on TimeoutException {
      return _handleException("Request timeout. Please try again.", 408);
    } catch (e) {
      return _handleException("Unexpected error: $e", 400);
    }
  }

  /// POST /auth/refresh-token  { refreshToken } → { data: { accessToken } }
  static Future<bool> refreshAccessToken() {
    _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
    return _refreshing!;
  }

  static Future<bool> _doRefresh() async {
    final refresh = SharePrefsHelper.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await http
          .post(
            Uri.parse(ApiUrl.refreshToken),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"refreshToken": refresh}),
          )
          .timeout(defaultTimeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final token = body['data']?['accessToken'];
        if (token is String && token.isNotEmpty) {
          await SharePrefsHelper.saveToken(token);
          final newRefresh = body['data']?['refreshToken'];
          if (newRefresh is String && newRefresh.isNotEmpty) {
            await SharePrefsHelper.saveRefreshToken(newRefresh);
          }
          SessionService.onTokenRefreshed();
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  ApiResult _handleResponse(http.Response response) {
    log.i("⇦ ${response.statusCode} ${response.request?.url}\n${_short(response.body)}");
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }
    return Response(
      statusCode: response.statusCode,
      body: decoded,
      bodyString: response.body,
      statusText: response.reasonPhrase,
      headers: response.headers,
    );
  }

  ApiResult _handleException(String message, int code) {
    log.e(message);
    return Response(statusCode: code, body: {"success": false, "message": message}, statusText: message);
  }

  void _logRequest(String url, String method) => log.i("⇨ $method $url");

  String _short(String s) => s.length > 1500 ? '${s.substring(0, 1500)}…' : s;

  // ======================== JSON METHODS ========================
  Future<ApiResult> get({
    required String url,
    Map<String, dynamic>? query,
    bool isBasic = false,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) async {
    final full = withQuery(url, query);
    return safeRequest(
      () async => http.get(Uri.parse(full),
          headers: await _headers(isToken: isToken, customHeaders: customHeaders)),
      url: full,
      method: "GET",
    );
  }

  Future<ApiResult> post({
    required String url,
    Map<String, dynamic>? body,
    bool isBasic = false,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) async {
    return safeRequest(
      () async => http.post(Uri.parse(url),
          body: jsonEncode(body ?? {}),
          headers: await _headers(isToken: isToken, customHeaders: customHeaders)),
      url: url,
      method: "POST",
    );
  }

  Future<ApiResult> put({
    required String url,
    Map<String, dynamic>? body,
    bool isBasic = false,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) async {
    return safeRequest(
      () async => http.put(Uri.parse(url),
          body: jsonEncode(body ?? {}),
          headers: await _headers(isToken: isToken, customHeaders: customHeaders)),
      url: url,
      method: "PUT",
    );
  }

  Future<ApiResult> patch({
    required String url,
    Map<String, dynamic>? body,
    bool isBasic = false,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) async {
    return safeRequest(
      () async => http.patch(Uri.parse(url),
          body: jsonEncode(body ?? {}),
          headers: await _headers(isToken: isToken, customHeaders: customHeaders)),
      url: url,
      method: "PATCH",
    );
  }

  Future<ApiResult> delete({
    required String url,
    Map<String, dynamic>? body,
    bool isBasic = false,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) async {
    return safeRequest(
      () async {
        final request = http.Request("DELETE", Uri.parse(url))
          ..headers.addAll(await _headers(isToken: isToken, customHeaders: customHeaders));
        if (body != null) request.body = jsonEncode(body);
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
      url: url,
      method: "DELETE",
    );
  }

  // ======================== MULTIPART ========================
  /// Multipart in the API's format: one text field `data` holding a JSON
  /// string, plus file fields. Sends plain JSON when there are no files.
  Future<ApiResult> sendForm({
    required String url,
    String method = "POST",
    Map<String, dynamic>? data,
    List<MultipartFileData> files = const [],
    bool isToken = true,
  }) async {
    final existing = files.where((f) => File(f.path).existsSync()).toList();
    if (existing.isEmpty) {
      switch (method) {
        case "PATCH":
          return patch(url: url, body: data, isToken: isToken);
        case "PUT":
          return put(url: url, body: data, isToken: isToken);
        default:
          return post(url: url, body: data, isToken: isToken);
      }
    }
    return safeRequest(
      () async {
        final request = http.MultipartRequest(method, Uri.parse(url));
        request.headers.addAll(await _headers(json: false, isToken: isToken));
        if (data != null) request.fields['data'] = jsonEncode(data);
        for (final f in existing) {
          final mime = (lookupMimeType(f.path) ?? 'application/octet-stream').split('/');
          request.files.add(await http.MultipartFile.fromPath(
            f.key,
            f.path,
            contentType: MediaType(mime[0], mime[1]),
          ));
        }
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
      url: url,
      method: "$method (multipart)",
      timeout: uploadTimeout,
    );
  }

  /// Raw multipart with explicit text fields (legacy callers).
  Future<ApiResult> multipart({
    required String url,
    required Map<String, String> fields,
    required List<MultipartFileData> files,
    String method = "POST",
    bool isBasic = false,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) async {
    return safeRequest(
      () async {
        final request = http.MultipartRequest(method, Uri.parse(url));
        request.headers.addAll(await _headers(json: false, isToken: isToken, customHeaders: customHeaders));
        request.fields.addAll(fields);
        for (final f in files) {
          if (!File(f.path).existsSync()) continue;
          final mime = (lookupMimeType(f.path) ?? 'application/octet-stream').split('/');
          request.files.add(await http.MultipartFile.fromPath(f.key, f.path,
              contentType: MediaType(mime[0], mime[1])));
        }
        final streamed = await request.send();
        return http.Response.fromStream(streamed);
      },
      url: url,
      method: "$method (multipart)",
      timeout: uploadTimeout,
    );
  }

  Future<ApiResult> patchWithMultipart({
    required String url,
    required Map<String, String> fields,
    File? imageFile,
    String fileKey = "insurance_Photo",
    bool isBasic = false,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) {
    return multipart(
      url: url,
      method: "PATCH",
      fields: fields,
      files: imageFile == null ? [] : [MultipartFileData(key: fileKey, path: imageFile.path)],
      customHeaders: customHeaders,
    );
  }

  Future<ApiResult> putMultipart({
    required String url,
    required String fileKey,
    required File file,
    Map<String, String> fields = const {},
    bool isBasic = false,
    bool isToken = true,
    Map<String, String>? customHeaders,
  }) {
    return multipart(
      url: url,
      method: "PUT",
      fields: fields,
      files: [MultipartFileData(key: fileKey, path: file.path)],
      customHeaders: customHeaders,
    );
  }

  /// Download any URL (with auth header) – used for .ics and exports.
  Future<http.Response?> download(String url) async {
    try {
      return await http
          .get(Uri.parse(url), headers: await _headers(json: false))
          .timeout(uploadTimeout);
    } catch (e) {
      log.e("Download error: $e");
      return null;
    }
  }
}

/// ================= Multipart File Model ========================
class MultipartFileData {
  final String key;
  final String path;

  MultipartFileData({required this.key, required this.path});

  String get mimeType => lookupMimeType(path) ?? "application/octet-stream";
}
