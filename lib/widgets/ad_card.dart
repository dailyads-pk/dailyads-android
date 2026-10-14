import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/saved_store.dart';
import '../screens/ad_detail_screen.dart';
import '../theme.dart';

class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key});
  final AdType type;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: type.bg, borderRadius: BorderRadius.circular(6)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(type.icon, size: 13, color: type.fg),
          const SizedBox(width: 4),
          Text(type.label, style: TextStyle(color: type.fg, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ]),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final closed = status.startsWith('Closed');
    final urgent = status.contains('today') || status.contains('tomorrow') || RegExp(r'in [1-3] days').hasMatch(status);
    final (bg, fg) = closed
        ? (Sheet.surface2, Sheet.text3)
        : urgent
            ? (Sheet.badBg, Sheet.badFg)
            : (Sheet.warnBg, Sheet.warnFg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}

class Clipping extends StatelessWidget {
  const Clipping(this.url, {super.key, this.fit = BoxFit.cover});
  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Sheet.surface2,
      alignment: Alignment.center,
      child: const Icon(Icons.newspaper, color: Sheet.text3),
    );
    if (url == null) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      alignment: Alignment.topCenter,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
      fadeInDuration: const Duration(milliseconds: 150),
    );
  }
}

class AdCard extends StatelessWidget {
  const AdCard(this.ad, {super.key, this.fallbackType});
  final AdSummary ad;

  /// Type to show when the card itself does not print one (e.g. on a
  /// category page every card is that category).
  final AdType? fallbackType;

  @override
  Widget build(BuildContext context) {
    final type = ad.typeLabel != null ? AdType.byLabel(ad.typeLabel) : (fallbackType ?? AdType.other);
    final meta = [ad.city, ad.newspaper, ad.date].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(AdDetailScreen.route(ad)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 84, height: 104, child: Clipping(ad.thumbUrl)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 6, runSpacing: 4, children: [
                  if (type != AdType.other) TypeBadge(type),
                  if (ad.status != null) StatusBadge(ad.status!),
                ]),
                const SizedBox(height: 6),
                Text(ad.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                if (ad.advertiser != null && ad.advertiser != ad.title) ...[
                  const SizedBox(height: 3),
                  Text(ad.advertiser!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Sheet.text2, fontSize: 13)),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Sheet.text3, fontSize: 12.5)),
                ],
              ]),
            ),
            ListenableBuilder(
              listenable: SavedStore.instance,
              builder: (context, _) {
                final saved = SavedStore.instance.isSaved(ad.id);
                return IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: saved ? 'Remove from saved' : 'Save',
                  onPressed: () => SavedStore.instance.toggle(ad),
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? Sheet.accent : Sheet.text3),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }
}
