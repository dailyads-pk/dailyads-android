import 'dart:io';

import 'package:dailyads/data/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  test('category listing: image-first cards', () {
    final page = parseListing(fixture('category.md'));
    expect(page.heading, 'Jobs');
    expect(page.summary, contains('jobs'));
    expect(page.ads.length, greaterThanOrEqualTo(40));
    for (final ad in page.ads) {
      expect(ad.id, greaterThan(0));
      expect(ad.url, startsWith('https://dailyads.pk/ad/${ad.id}'));
      expect(ad.thumbUrl, isNotNull, reason: 'ad ${ad.id} has no thumbnail');
      expect(ad.newspaper, isNotNull);
      expect(ad.city, isNot(contains(ad.newspaper!)), reason: 'city "${ad.city}" still holds the paper');
    }
  });

  test('closing soon: image-last cards carry type and deadline', () {
    final page = parseListing(fixture('closing.md'));
    expect(page.ads, isNotEmpty);
    final first = page.ads.first;
    expect(first.typeLabel, isNotNull);
    expect(first.status, isNotNull);
    expect(page.ads.where((a) => a.thumbUrl != null).length, greaterThan(page.ads.length ~/ 2));
  });

  test('home gives the latest edition date', () {
    expect(parseLatestDate(fixture('home.md')), matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  test('newspapers list', () {
    final papers = parseNewspapers(fixture('newspaper.md'));
    expect(papers.length, greaterThanOrEqualTo(8));
    expect(papers.map((p) => p.slug), contains('dawn'));
  });

  test('ad detail', () {
    final d = parseDetail(fixture('detail.md'), 'https://dailyads.pk/ad/89253/x');
    expect(d.id, 89253);
    expect(d.title, startsWith('PESCO Career'));
    expect(d.fact('Newspaper'), 'Dawn');
    expect(d.fact('City'), 'Peshawar');
    expect(d.fact('Ad type'), 'Jobs');
    expect(d.fact('Published'), 'Saturday, 10 October 2026');
    expect(d.body, contains('| Sr# |'));
    expect(d.clippingUrl, startsWith('https://dailyads.pk/api/image'));
    expect(d.originalUrl, startsWith('https://e.dawn.com'));
    expect(d.related, isNotEmpty);
  });
}
