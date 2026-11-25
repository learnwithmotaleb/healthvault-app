import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:get/get.dart';

import '../../../core/routes/route_path.dart';
import '../../../data/models/app_models.dart';
import '../../../data/models/json.dart';
import '../../../service/api_service.dart';
import '../../../service/api_url.dart';
import '../../../utils/app_colors/app_colors.dart';
import '../../../utils/app_text_style/app_text_style.dart';
import '../../../utils/static_strings/static_strings.dart';
import '../../widget/custom_appbar.dart';
import '../../widget/hv_ui.dart';

/// About / Terms / Privacy – `{ description (HTML) }` or `data: null`.
class HtmlPageScreen extends StatefulWidget {
  final String title;
  final String url;
  const HtmlPageScreen({super.key, required this.title, required this.url});

  @override
  State<HtmlPageScreen> createState() => _HtmlPageScreenState();
}

class _HtmlPageScreenState extends State<HtmlPageScreen> {
  bool loading = true;
  String? html;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    final res = await ApiClient().get(url: widget.url, isToken: false);
    if (!mounted) return;
    setState(() {
      loading = false;
      if (res.isOk) {
        final d = res.data;
        html = d is Map ? J.str(d['description']) : (d is List && d.isNotEmpty ? J.str(J.map(d.first)['description']) : null);
      } else {
        error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: widget.title),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? ErrorView(message: error!, onRetry: _load)
              : (html == null || html!.trim().isEmpty)
                  ? EmptyView(icon: Icons.article_outlined, title: 'Coming soon'.tr, subtitle: 'This page has not been published yet.'.tr)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(padding: const EdgeInsets.all(16), children: [
                        HtmlWidget(html!, textStyle: AppTextStyles.body.copyWith(height: 1.5)),
                      ]),
                    ),
    );
  }
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  @override
  Widget build(BuildContext context) => HtmlPageScreen(title: 'About us'.tr, url: ApiUrl.getAboutUs);
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) => HtmlPageScreen(title: AppStrings.termsAndCondition.tr, url: ApiUrl.getTermsAndCondition);
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => HtmlPageScreen(title: AppStrings.privacyPolicy.tr, url: ApiUrl.privacyPolicy);
}

// ================================================================= FAQ
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  bool loading = true;
  String? error;
  List<FaqModel> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final res = await ApiClient().get(url: ApiUrl.getFag, isToken: false);
    if (!mounted) return;
    setState(() {
      loading = false;
      error = res.isOk ? null : res.message;
      items = res.isOk ? Paged.parse(res.data, FaqModel.fromJson).items : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.faq.tr),
      body: AsyncList(
        loading: loading,
        error: error,
        isEmpty: items.isEmpty,
        onRefresh: _load,
        empty: EmptyView(icon: Icons.help_outline, title: 'No questions yet'.tr),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (_, i) => HVCardBox(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: AppColors.primaryColor,
                collapsedIconColor: AppColors.primaryColor,
                title: Text(items[i].question, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [HtmlWidget(items[i].answer, textStyle: AppTextStyles.body.copyWith(color: AppColors.labelColor))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================= Articles
class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});
  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final search = TextEditingController();
  final items = <ArticleModel>[];
  bool loading = true;
  bool loadingMore = false;
  String? error;
  int page = 1;
  bool hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (!hasMore || loadingMore)) return;
    setState(() => more ? loadingMore = true : loading = true);
    final p = more ? page + 1 : 1;
    final res = await ApiClient().get(
      url: ApiUrl.getAllArticle,
      isToken: false,
      query: {"page": p, "limit": 10, "searchTerm": search.text.trim()},
    );
    if (!mounted) return;
    setState(() {
      loading = false;
      loadingMore = false;
      if (res.isOk) {
        final paged = Paged.parse(res.data, ArticleModel.fromJson);
        if (!more) items.clear();
        items.addAll(paged.items);
        page = p;
        hasMore = paged.hasMore;
        error = null;
      } else {
        error = res.message;
      }
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.healthANDWellnessArticles.tr),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Search articles'.tr,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) _load(more: true);
              return false;
            },
            child: AsyncList(
              loading: loading,
              error: error,
              isEmpty: items.isEmpty,
              onRefresh: _load,
              empty: EmptyView(icon: Icons.article_outlined, title: 'No articles'.tr),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length + (loadingMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= items.length) return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                  final a = items[i];
                  return HVCardBox(
                    padding: EdgeInsets.zero,
                    onTap: () => Get.toNamed(RoutePath.healthDetail, arguments: {'articleId': a.id}),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ApiImage(a.image,
                          height: 170,
                          width: double.infinity,
                          radius: const BorderRadius.vertical(top: Radius.circular(14))),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.title, style: AppTextStyles.title.copyWith(fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(Fmt.date(a.createdAt), style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.hintColor)),
                        ]),
                      ),
                    ]),
                  );
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class ArticleDetailsScreen extends StatefulWidget {
  const ArticleDetailsScreen({super.key});
  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  ArticleModel? a;
  bool loading = true;
  String? error;
  late final String id;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    id = args is Map ? (args['articleId'] ?? args['id'] ?? '').toString() : args?.toString() ?? '';
    _load();
  }

  Future<void> _load() async {
    final res = await ApiClient().get(url: ApiUrl.getSingeArticle(id), isToken: false);
    if (!mounted) return;
    setState(() {
      loading = false;
      if (res.isOk && res.data is Map) {
        a = ArticleModel.fromJson(J.map(res.data));
      } else {
        error = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CommonAppBar(title: AppStrings.healthANDWellnessArticles.tr),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : a == null
              ? ErrorView(message: error ?? 'Not found'.tr, onRetry: _load)
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if ((a!.image ?? '').isNotEmpty)
                    ApiImage(a!.image, height: 210, width: double.infinity, radius: BorderRadius.circular(14)),
                  const SizedBox(height: 14),
                  Text(a!.title, style: AppTextStyles.title.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(Fmt.date(a!.createdAt), style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.hintColor)),
                  const SizedBox(height: 12),
                  HtmlWidget(a!.details, textStyle: AppTextStyles.body.copyWith(height: 1.6)),
                ]),
    );
  }
}
