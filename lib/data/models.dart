/// Plain data objects read from dailyads.pk's markdown pages.
library;

class AdSummary {
  const AdSummary({
    required this.id,
    required this.title,
    required this.url,
    this.advertiser,
    this.city,
    this.newspaper,
    this.date,
    this.typeLabel,
    this.status,
    this.thumbUrl,
  });

  final int id;
  final String title;
  final String url;
  final String? advertiser;
  final String? city;
  final String? newspaper;
  final String? date;

  /// Plural ad-type label as the site prints it, e.g. "Tenders".
  final String? typeLabel;

  /// Deadline status, e.g. "Due in 5 days", "Closes 29 Oct 2026", "Closed".
  final String? status;
  final String? thumbUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'advertiser': advertiser,
        'city': city,
        'newspaper': newspaper,
        'date': date,
        'typeLabel': typeLabel,
        'status': status,
        'thumbUrl': thumbUrl,
      };

  factory AdSummary.fromJson(Map<String, dynamic> j) => AdSummary(
        id: j['id'] as int,
        title: j['title'] as String,
        url: j['url'] as String,
        advertiser: j['advertiser'] as String?,
        city: j['city'] as String?,
        newspaper: j['newspaper'] as String?,
        date: j['date'] as String?,
        typeLabel: j['typeLabel'] as String?,
        status: j['status'] as String?,
        thumbUrl: j['thumbUrl'] as String?,
      );
}

class AdListPage {
  const AdListPage({required this.ads, this.heading, this.summary});

  final List<AdSummary> ads;

  /// The page's H1, e.g. "Jobs".
  final String? heading;

  /// The count line under the heading, e.g. "3,201 jobs in the last 30 days".
  final String? summary;
}

class LinkRef {
  const LinkRef(this.label, this.url);
  final String label;
  final String url;
}

class AdDetail {
  const AdDetail({
    required this.id,
    required this.title,
    required this.url,
    required this.intro,
    required this.facts,
    required this.body,
    this.clippingUrl,
    this.originalUrl,
    this.related = const [],
  });

  final int id;
  final String title;
  final String url;
  final String intro;

  /// "Key facts" in page order, link markup removed.
  final List<MapEntry<String, String>> facts;

  /// The advertisement text as markdown.
  final String body;
  final String? clippingUrl;

  /// The advertiser's own page or the newspaper's e-paper page.
  final String? originalUrl;
  final List<LinkRef> related;

  String? fact(String key) {
    for (final f in facts) {
      if (f.key.toLowerCase() == key.toLowerCase()) return f.value;
    }
    return null;
  }

  AdSummary toSummary() => AdSummary(
        id: id,
        title: title,
        url: url,
        advertiser: fact('Advertiser'),
        city: fact('City'),
        newspaper: fact('Newspaper'),
        date: fact('Published'),
        typeLabel: fact('Ad type'),
        thumbUrl: clippingUrl == null ? null : '$clippingUrl&w=320&thumb=1',
      );
}

class Newspaper {
  const Newspaper(this.name, this.slug, this.count);
  final String name;
  final String slug;
  final int? count;
}
