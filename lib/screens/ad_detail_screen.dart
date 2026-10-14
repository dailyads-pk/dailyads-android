import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../data/saved_store.dart';
import '../data/site_client.dart';
import '../theme.dart';
import '../widgets/ad_card.dart';
import '../widgets/states.dart';

class AdDetailScreen extends StatefulWidget {
  const AdDetailScreen({super.key, required this.summary});
  final AdSummary summary;

  static Route<void> route(AdSummary ad) => MaterialPageRoute(builder: (_) => AdDetailScreen(summary: ad));

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  late Future<AdDetail> _future = SiteClient.instance.detail(widget.summary.url);

  Future<void> _open(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn’t open the link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.summary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advertisement'),
        actions: [
          ListenableBuilder(
            listenable: SavedStore.instance,
            builder: (context, _) {
              final saved = SavedStore.instance.isSaved(s.id);
              return IconButton(
                tooltip: saved ? 'Remove from saved' : 'Save',
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? Sheet.accent : null),
                onPressed: () async {
                  final d = await _future.then<AdDetail?>((d) => d, onError: (_) => null);
                  final ad = d?.toSummary() ?? s;
                  await SavedStore.instance.toggle(ad.thumbUrl == null ? s : ad);
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => SharePlus.instance.share(ShareParams(text: '${s.title}\n${s.url}')),
          ),
        ],
      ),
      body: FutureBuilder<AdDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(snap.error!, onRetry: () => setState(() => _future = SiteClient.instance.detail(s.url)));
          }
          if (!snap.hasData) {
            return Column(children: [
              Padding(padding: const EdgeInsets.all(16), child: Text(s.title, style: Theme.of(context).textTheme.headlineSmall)),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ]);
          }
          return _body(context, snap.data!);
        },
      ),
    );
  }

  Widget _body(BuildContext context, AdDetail d) {
    final type = AdType.byLabel(d.fact('Ad type') ?? widget.summary.typeLabel);
    final text = Theme.of(context).textTheme;
    final lastDate = d.fact('Last date');
    final factKeys = ['Advertiser', 'City', 'Newspaper', 'Published', 'Last date'];

    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
      Wrap(spacing: 6, runSpacing: 4, children: [
        if (type != AdType.other) TypeBadge(type),
        if (widget.summary.status != null) StatusBadge(widget.summary.status!),
      ]),
      const SizedBox(height: 8),
      Text(d.title, style: text.headlineSmall),
      if (lastDate != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: Sheet.accentSoft, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.event_outlined, color: Sheet.accentText, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text('Last date: $lastDate', style: const TextStyle(color: Sheet.accentText, fontWeight: FontWeight.w600))),
          ]),
        ),
      ],
      if (d.clippingUrl != null) ...[
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _ClippingViewer(d.clippingUrl!, d.title))),
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Sheet.surface,
                constraints: const BoxConstraints(maxHeight: 420),
                width: double.infinity,
                child: Clipping(d.clippingUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Sheet.ink.withValues(alpha: .75), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Tap to zoom', style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            for (final k in factKeys)
              if (d.fact(k) != null)
                ListTile(
                  dense: true,
                  title: Text(k, style: const TextStyle(color: Sheet.text3, fontSize: 12.5)),
                  subtitle: Text(d.fact(k)!, style: const TextStyle(color: Sheet.text, fontSize: 15)),
                ),
          ]),
        ),
      ),
      if (d.body.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('Advertisement text', style: text.titleLarge),
        const SizedBox(height: 8),
        MarkdownBody(
          data: d.body,
          selectable: true,
          onTapLink: (_, href, _) => href == null ? null : _open(href),
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: const TextStyle(fontSize: 15, height: 1.5, color: Sheet.text),
            tableBody: const TextStyle(fontSize: 12.5),
            tableHead: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            tableBorder: TableBorder.all(color: Sheet.border),
            tableCellsPadding: const EdgeInsets.all(6),
            tableColumnWidth: const FlexColumnWidth(),
          ),
        ),
      ],
      const SizedBox(height: 20),
      if (d.originalUrl != null)
        FilledButton.icon(
          onPressed: () => _open(d.originalUrl!),
          icon: const Icon(Icons.open_in_new),
          label: const Text('View original source'),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => _open(d.url),
        icon: const Icon(Icons.language),
        label: const Text('Open on DailyAds.pk'),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Sheet.surface2, borderRadius: BorderRadius.circular(10)),
        child: const Text(
          'DailyAds.pk is an independent archive of newspaper advertisements. It is not affiliated with any '
          'government body, advertiser or newspaper, and applications are not submitted through this app. '
          'Always check the original advertisement and the advertiser’s official website before you apply or respond.',
          style: TextStyle(fontSize: 12.5, color: Sheet.text2, height: 1.4),
        ),
      ),
      if (d.related.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Related advertisements', style: text.titleLarge),
        const SizedBox(height: 4),
        for (final r in d.related)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(r.label, style: text.titleMedium?.copyWith(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final id = int.tryParse(RegExp(r'/ad/(\d+)').firstMatch(r.url)?[1] ?? '') ?? 0;
              Navigator.of(context).push(AdDetailScreen.route(AdSummary(id: id, title: r.label, url: r.url)));
            },
          ),
      ],
    ]);
  }
}

class _ClippingViewer extends StatelessWidget {
  const _ClippingViewer(this.url, this.title);
  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (_, _) => const Center(child: CircularProgressIndicator(color: Colors.white)),
            errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
          ),
        ),
      ),
    );
  }
}
