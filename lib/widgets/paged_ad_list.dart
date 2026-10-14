import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/site_client.dart';
import '../theme.dart';
import 'ad_card.dart';
import 'states.dart';

/// An infinitely scrolling list of the ads on a dailyads.pk listing path.
class PagedAdList extends StatefulWidget {
  const PagedAdList({super.key, required this.path, this.fallbackType, this.header, this.emptyTitle = 'No ads found', this.emptyMessage});

  final String path;
  final AdType? fallbackType;

  /// Optional widget above the first card; receives the page heading summary.
  final Widget Function(BuildContext context, String? summary)? header;
  final String emptyTitle;
  final String? emptyMessage;

  @override
  State<PagedAdList> createState() => _PagedAdListState();
}

class _PagedAdListState extends State<PagedAdList> {
  final _ads = <AdSummary>[];
  final _ids = <int>{};
  String? _summary;
  int _page = 0;
  bool _loading = false;
  bool _done = false;
  Object? _error;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 800) _loadMore();
    });
    _loadMore();
  }

  @override
  void didUpdateWidget(PagedAdList old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _refresh();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _ads.clear();
      _ids.clear();
      _page = 0;
      _done = false;
      _error = null;
      _summary = null;
    });
    await _loadMore(fresh: true);
  }

  Future<void> _loadMore({bool fresh = false}) async {
    if (_loading || _done) return;
    final path = widget.path;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await SiteClient.instance.listing(path, page: _page + 1, fresh: fresh);
      if (!mounted || path != widget.path) return;
      final fresh_ = page.ads.where((a) => _ids.add(a.id)).toList();
      setState(() {
        _page++;
        _summary ??= page.summary;
        _ads.addAll(fresh_);
        // Pages past the end, or a page that repeats the previous one, end the list.
        if (fresh_.isEmpty) _done = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Keep filling until the viewport scrolls.
    if (mounted && !_done && _error == null && _scroll.hasClients && _scroll.position.maxScrollExtent < 200) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ads.isEmpty && _error != null) return ErrorView(_error!, onRetry: _refresh);
    if (_ads.isEmpty && _done) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(children: [
          if (widget.header != null) widget.header!(context, _summary),
          SizedBox(height: 360, child: MessageView(icon: Icons.search_off, title: widget.emptyTitle, message: widget.emptyMessage)),
        ]),
      );
    }
    if (_ads.isEmpty) return const Center(child: CircularProgressIndicator());

    final hasHeader = widget.header != null;
    final offset = hasHeader ? 1 : 0;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _ads.length + offset + 1,
        separatorBuilder: (_, i) => SizedBox(height: i == 0 && hasHeader ? 4 : 10),
        itemBuilder: (context, i) {
          if (hasHeader && i == 0) return widget.header!(context, _summary);
          final idx = i - offset;
          if (idx < _ads.length) return AdCard(_ads[idx], fallbackType: widget.fallbackType);
          if (_error != null) {
            return Center(child: TextButton.icon(onPressed: _loadMore, icon: const Icon(Icons.refresh), label: const Text('Couldn’t load more. Retry')));
          }
          if (_done) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('You’ve reached the end', style: TextStyle(color: Sheet.text3))),
            );
          }
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
