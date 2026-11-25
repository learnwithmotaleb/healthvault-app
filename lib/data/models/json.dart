/// Small, tolerant JSON readers so models never crash on unexpected shapes.
class J {
  static Map<String, dynamic> map(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static String? str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is Map && v['_id'] != null) return v['_id'].toString();
    return v.toString();
  }

  static String s(dynamic v, [String fallback = '']) => str(v) ?? fallback;

  static int? integer(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static bool b(dynamic v, [bool fallback = false]) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static DateTime? date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  static List<String> strings(dynamic v) {
    if (v is List) return v.where((e) => e != null).map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty) return [v];
    return [];
  }

  static List<T> list<T>(dynamic v, T Function(Map<String, dynamic>) f) {
    if (v is! List) return [];
    return v.whereType<Map>().map((e) => f(Map<String, dynamic>.from(e))).toList();
  }

  /// First non-null map among the given keys (e.g. `provider` or `providerId`).
  static Map<String, dynamic>? firstMap(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is Map) return Map<String, dynamic>.from(v);
      if (v is List && v.isNotEmpty && v.first is Map) {
        return Map<String, dynamic>.from(v.first);
      }
    }
    return null;
  }
}

/// `{ meta, data: [...] }` paginated envelope.
class Paged<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPage;
  final Map<String, dynamic> meta;

  Paged({
    required this.items,
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPage = 1,
    this.meta = const {},
  });

  bool get hasMore => page < totalPage;

  static Paged<T> parse<T>(dynamic data, T Function(Map<String, dynamic>) f) {
    if (data is List) {
      final items = J.list(data, f);
      return Paged(items: items, total: items.length, limit: items.length);
    }
    final m = J.map(data);
    final meta = J.map(m['meta']);
    return Paged(
      items: J.list(m['data'], f),
      page: J.integer(meta['page']) ?? 1,
      limit: J.integer(meta['limit']) ?? 10,
      total: J.integer(meta['total']) ?? 0,
      totalPage: J.integer(meta['totalPage']) ?? 1,
      meta: meta,
    );
  }
}
