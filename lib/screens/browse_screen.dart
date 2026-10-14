import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/site_client.dart';
import '../theme.dart';
import 'listing_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  late Future<List<Newspaper>> _papers = SiteClient.instance.newspapers();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text('Ad types', style: text.titleLarge),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [for (final t in AdType.all) _TypeTile(t)],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer_outlined, color: Sheet.badFg),
              title: const Text('Closing soon'),
              subtitle: const Text('Deadlines in the next few days'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(ListingScreen.route('Closing soon', '/closing-soon')),
            ),
          ),
          const SizedBox(height: 24),
          Text('Newspapers', style: text.titleLarge),
          const SizedBox(height: 8),
          FutureBuilder<List<Newspaper>>(
            future: _papers,
            builder: (context, snap) {
              if (snap.hasError) {
                return TextButton.icon(
                  onPressed: () => setState(() => _papers = SiteClient.instance.newspapers()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Couldn’t load newspapers. Retry'),
                );
              }
              if (!snap.hasData) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
              return Card(
                child: Column(children: [
                  for (final (i, p) in snap.data!.indexed) ...[
                    if (i > 0) const Divider(indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.newspaper, color: Sheet.primary),
                      title: Text(p.name),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(ListingScreen.route(p.name, '/newspaper/${p.slug}')),
                    ),
                  ],
                ]),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Cities', style: text.titleLarge),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (name, slug) in popularCities)
              ActionChip(
                avatar: const Icon(Icons.place_outlined, size: 16),
                label: Text(name),
                onPressed: () => Navigator.of(context).push(ListingScreen.route(name, '/city/$slug')),
              ),
          ]),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile(this.type);
  final AdType type;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: type.bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(ListingScreen.route(type.label, type.path, type: type)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(type.icon, color: type.solid),
            const Spacer(),
            Text(type.label, style: TextStyle(fontFamily: Sheet.serif, fontWeight: FontWeight.w700, fontSize: 16, color: type.fg)),
            SizedBox(
              height: 30,
              child: Text(type.short, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, height: 1.25, color: type.fg.withValues(alpha: .8))),
            ),
          ]),
        ),
      ),
    );
  }
}
