import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/site_client.dart';
import '../theme.dart';
import '../widgets/ad_card.dart';
import '../widgets/paged_ad_list.dart';
import '../widgets/states.dart';
import 'about_screen.dart';
import 'ad_detail_screen.dart';
import 'listing_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Future<String?> _latest = SiteClient.instance.latestDate();
  AdType? _type;

  void _reload() => setState(() => _latest = SiteClient.instance.latestDate(fresh: true));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _Wordmark(),
        actions: [
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _latest,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(snap.error!, onRetry: _reload);
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final date = snap.data!;
          final path = _type == null ? '/date/$date' : '/archive/date/$date/category/${_type!.slug}';
          return PagedAdList(
            key: ValueKey(path),
            path: path,
            fallbackType: _type,
            emptyTitle: 'No ${_type?.label.toLowerCase() ?? 'ads'} in this edition',
            emptyMessage: 'Try another ad type, or browse the archive.',
            header: (context, summary) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Latest edition', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Sheet.accentText)),
              const SizedBox(height: 2),
              Text(_formatDate(date), style: Theme.of(context).textTheme.headlineSmall),
              if (summary != null) ...[
                const SizedBox(height: 4),
                Text(summary, style: const TextStyle(color: Sheet.text2)),
              ],
              const SizedBox(height: 12),
              _TypeChips(selected: _type, onSelected: (t) => setState(() => _type = t)),
              if (_type == null) const _ClosingSoonStrip(),
              const SizedBox(height: 8),
            ]),
          );
        },
      ),
    );
  }
}

String _formatDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();
  @override
  Widget build(BuildContext context) => const Text.rich(TextSpan(children: [
        TextSpan(text: 'DailyAds'),
        TextSpan(text: '.pk', style: TextStyle(color: Sheet.accent)),
      ]));
}

class _TypeChips extends StatelessWidget {
  const _TypeChips({required this.selected, required this.onSelected});
  final AdType? selected;
  final ValueChanged<AdType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: const Text('All'), selected: selected == null, onSelected: (_) => onSelected(null)),
          ),
          for (final t in AdType.all)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(t.icon, size: 16, color: t.fg),
                label: Text(t.label),
                selected: selected == t,
                selectedColor: t.bg,
                onSelected: (_) => onSelected(selected == t ? null : t),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClosingSoonStrip extends StatefulWidget {
  const _ClosingSoonStrip();
  @override
  State<_ClosingSoonStrip> createState() => _ClosingSoonStripState();
}

class _ClosingSoonStripState extends State<_ClosingSoonStrip> {
  static Future<AdListPage>? _cached;
  late final Future<AdListPage> _future = _cached ??= SiteClient.instance.listing('/closing-soon');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdListPage>(
      future: _future,
      builder: (context, snap) {
        final ads = (snap.data?.ads ?? const <AdSummary>[]).where((a) => a.status != null && !a.status!.startsWith('Closed')).take(12).toList();
        if (ads.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.timer_outlined, size: 18, color: Sheet.badFg),
            const SizedBox(width: 6),
            Text('Closing soon', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).push(ListingScreen.route('Closing soon', '/closing-soon')),
              child: const Text('See all'),
            ),
          ]),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ads.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _MiniCard(ads[i]),
            ),
          ),
          const SizedBox(height: 8),
          Text('All ads in this edition', style: Theme.of(context).textTheme.titleMedium),
        ]);
      },
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard(this.ad);
  final AdSummary ad;

  @override
  Widget build(BuildContext context) {
    final type = AdType.byLabel(ad.typeLabel);
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(AdDetailScreen.route(ad)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (type != AdType.other) TypeBadge(type),
                if (ad.status != null) StatusBadge(ad.status!),
              ]),
              const SizedBox(height: 6),
              Expanded(
                child: Text(ad.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14.5)),
              ),
              Text([ad.city, ad.newspaper].whereType<String>().join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Sheet.text3, fontSize: 12)),
            ]),
          ),
        ),
      ),
    );
  }
}
