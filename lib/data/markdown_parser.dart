/// Parses the markdown that dailyads.pk serves for `Accept: text/markdown`.
///
/// Listing pages print each advertisement as a short run of lines:
///
///     ![Newspaper clipping: <alt title>, <Newspaper>, <10 Oct 2026>](<image>)
///     Tenders Due in 5 days               <- optional type/deadline badge
///     ### [<Title>](https://dailyads.pk/ad/<id>/<slug>)
///     <Advertiser>
///     <City> <Newspaper> [<date>]
///
/// Some pages (closing soon) print the image after the card instead of
/// before it, so the parser detects the order from the first card.
library;

import 'models.dart';

const typeLabels = [
  'Court Notices',
  'Jobs',
  'Tenders',
  'Admissions',
  'Notices',
  'Property',
  'Auctions',
  'Results',
];

final _imageLine = RegExp(r'^!\[Newspaper clipping: (.*)\]\((\S+)\)\s*$');
final _cardHeading =
    RegExp(r'^### \[(.+)\]\((https://dailyads\.pk/ad/(\d+)(?:/[^)\s]*)?)\)\s*$');
final _link = RegExp(r'\[([^\]]*)\]\(([^)\s]+)\)');
final _bold = RegExp(r'\*\*([^*]+)\*\*');
final _dateTail = RegExp(r'\s*(\d{1,2} [A-Z][a-z]{2} \d{4})$');

String stripInline(String s) => s
    .replaceAllMapped(_link, (m) => m[1]!)
    .replaceAllMapped(_bold, (m) => m[1]!)
    .replaceAll(r'—', '—')
    .trim();

/// Returns the body of the page without its YAML front matter.
String _body(String md) {
  if (md.startsWith('---')) {
    final end = md.indexOf('\n---', 3);
    if (end > 0) return md.substring(end + 4);
  }
  return md;
}

AdListPage parseListing(String md) {
  final lines = _body(md).split('\n').map((l) => l.trimRight()).toList();
  String? heading;
  String? summary;

  final firstImage = lines.indexWhere((l) => _imageLine.hasMatch(l));
  final firstCard = lines.indexWhere((l) => _cardHeading.hasMatch(l));
  final imageFirst = firstImage >= 0 && firstImage < firstCard;

  final ads = <AdSummary>[];
  final seen = <int>{};
  RegExpMatch? pendingImage;
  String? pendingBadge;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (heading == null && line.startsWith('# ')) {
      heading = stripInline(line.substring(2));
      continue;
    }
    if (summary == null && heading != null && line.startsWith('**')) {
      summary = stripInline(line);
      continue;
    }

    final img = _imageLine.firstMatch(line);
    if (img != null) {
      if (imageFirst) {
        pendingImage = img;
        pendingBadge = null;
      } else if (ads.isNotEmpty && ads.last.thumbUrl == null) {
        ads[ads.length - 1] = _withImage(ads.last, img);
      }
      continue;
    }

    final card = _cardHeading.firstMatch(line);
    if (card == null) {
      if (line.isNotEmpty &&
          !line.startsWith('#') &&
          !line.startsWith('[') &&
          !line.startsWith('-') &&
          !line.startsWith('!') &&
          line.length < 60) {
        pendingBadge = line;
      } else if (line.startsWith('#')) {
        pendingBadge = null;
      }
      continue;
    }

    // Collect the advertiser and the city/newspaper line that follow.
    final tail = <String>[];
    var j = i + 1;
    while (j < lines.length && tail.length < 2) {
      final l = lines[j];
      if (l.isEmpty) {
        j++;
        continue;
      }
      if (l.startsWith('#') || l.startsWith('!') || l.startsWith('[') || l.startsWith('-')) break;
      if (_cardHeading.hasMatch(l)) break;
      // A badge belonging to the next card in image-last layout.
      if (!imageFirst && tail.length == 2) break;
      tail.add(l);
      j++;
    }
    if (!imageFirst && tail.length == 2 && _looksLikeBadge(tail[1])) {
      tail.removeLast();
    }

    final id = int.parse(card[3]!);
    final (typeLabel, status) = _splitBadge(pendingBadge);
    pendingBadge = null;
    var ad = AdSummary(
      id: id,
      title: stripInline(card[1]!),
      url: card[2]!,
      advertiser: tail.isNotEmpty ? stripInline(tail[0]) : null,
      typeLabel: typeLabel,
      status: status,
    );
    ad = _withMeta(ad, tail.length > 1 ? stripInline(tail[1]) : null);
    if (imageFirst && pendingImage != null) {
      ad = _withImage(ad, pendingImage);
      pendingImage = null;
    }
    if (seen.add(id)) ads.add(ad);
  }

  return AdListPage(ads: ads, heading: heading, summary: summary);
}

bool _looksLikeBadge(String l) =>
    typeLabels.any((t) => l.startsWith('$t ')) || l.startsWith('Closed') || l.startsWith('Closes') || l.startsWith('Due');

(String?, String?) _splitBadge(String? badge) {
  if (badge == null) return (null, null);
  for (final t in typeLabels) {
    if (badge == t) return (t, null);
    if (badge.startsWith('$t ')) return (t, badge.substring(t.length + 1).trim());
  }
  if (_looksLikeBadge(badge)) return (null, badge);
  return (null, null);
}

AdSummary _withImage(AdSummary ad, RegExpMatch img) {
  // Alt text ends with ", <Newspaper>, <date>".
  final parts = img[1]!.split(', ');
  String? paper = ad.newspaper;
  String? date = ad.date;
  if (parts.length >= 3) {
    date ??= parts.last;
    paper ??= parts[parts.length - 2];
  }
  var city = ad.city;
  if (city != null && paper != null && city.endsWith(' $paper')) {
    city = city.substring(0, city.length - paper.length - 1).trim();
  }
  return AdSummary(
    id: ad.id,
    title: ad.title,
    url: ad.url,
    advertiser: ad.advertiser,
    city: city,
    newspaper: paper,
    date: date,
    typeLabel: ad.typeLabel,
    status: ad.status,
    thumbUrl: img[2]!,
  );
}

/// The meta line is `<City> <Newspaper> [<date>]` with no separators. The
/// newspaper is resolved later from the image alt text, so for now the whole
/// line minus the date is kept in [city] and trimmed once the paper is known.
AdSummary _withMeta(AdSummary ad, String? meta) {
  if (meta == null) return ad;
  String? date;
  var rest = meta;
  final d = _dateTail.firstMatch(rest);
  if (d != null) {
    date = d[1];
    rest = rest.substring(0, d.start).trim();
  }
  return AdSummary(
    id: ad.id,
    title: ad.title,
    url: ad.url,
    advertiser: ad.advertiser,
    city: rest.isEmpty ? null : rest,
    date: date,
    typeLabel: ad.typeLabel,
    status: ad.status,
  );
}

AdDetail parseDetail(String md, String url) {
  final body = _body(md);
  final lines = body.split('\n');
  String title = '';
  final intro = StringBuffer();
  final facts = <MapEntry<String, String>>[];
  final text = StringBuffer();
  final related = <LinkRef>[];
  String? clipping;
  String? original;
  int? id;

  var section = '';
  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.startsWith('# ')) {
      title = stripInline(line.substring(2));
      section = 'intro';
      continue;
    }
    if (line.startsWith('## ')) {
      section = line.substring(3).trim().toLowerCase();
      continue;
    }
    switch (section) {
      case 'intro':
        if (line.isNotEmpty) intro.writeln(stripInline(line));
      case 'key facts':
        final m = RegExp(r'^- \*\*(.+?)\*\*:\s*(.*)$').firstMatch(line);
        if (m != null) {
          final value = stripInline(m[2]!).replaceAll(RegExp(r'\s*\(all ads that day\)'), '');
          facts.add(MapEntry(m[1]!, value));
          if (m[1] == 'Ad ID') id = int.tryParse(value);
        }
      case 'advertisement text':
        text.writeln(raw);
      case 'source':
        final m = RegExp(r'^- (.+?):\s*(https?://\S+)').firstMatch(line);
        if (m != null) {
          final k = m[1]!.toLowerCase();
          if (k.startsWith('original clipping')) clipping = m[2];
          if (k.startsWith('advertiser')) original = m[2];
        }
      case 'related advertisements':
        final m = RegExp(r'^- \[(.+?)\]\((https://dailyads\.pk/ad/[^)]+)\)').firstMatch(line);
        if (m != null) related.add(LinkRef(stripInline(m[1]!), m[2]!));
    }
  }

  id ??= int.tryParse(RegExp(r'/ad/(\d+)').firstMatch(url)?[1] ?? '') ?? 0;
  return AdDetail(
    id: id,
    title: title,
    url: url,
    intro: intro.toString().trim(),
    facts: facts,
    body: text.toString().trim(),
    clippingUrl: clipping,
    originalUrl: original,
    related: related,
  );
}

/// The newspaper filter on a `/newspaper/<slug>` page lists every paper.
List<Newspaper> parseNewspapers(String md) {
  final re = RegExp(r'\[([^\]*]+?) \*\*([\d,]+)\*\*\]\(https://dailyads\.pk/newspaper/([a-z0-9-]+)\)');
  final out = <Newspaper>[];
  final seen = <String>{};
  for (final m in re.allMatches(md)) {
    if (seen.add(m[3]!)) {
      out.add(Newspaper(m[1]!.trim(), m[3]!, int.tryParse(m[2]!.replaceAll(',', ''))));
    }
  }
  return out;
}

/// The homepage's "See all" link points at the latest edition's date page.
String? parseLatestDate(String md) =>
    RegExp(r'https://dailyads\.pk/date/(\d{4}-\d{2}-\d{2})').firstMatch(md)?[1];
