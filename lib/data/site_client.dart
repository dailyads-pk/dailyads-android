import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'markdown_parser.dart';
import 'models.dart';

const siteOrigin = 'https://dailyads.pk';

class SiteException implements Exception {
  SiteException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads public pages from dailyads.pk in their markdown rendering.
class SiteClient {
  SiteClient._();
  static final instance = SiteClient._();

  final _http = http.Client();
  final _cache = <String, (DateTime, String)>{};
  static const _ttl = Duration(minutes: 5);

  Future<String> _get(String pathOrUrl, {bool fresh = false}) async {
    final url = pathOrUrl.startsWith('http') ? pathOrUrl : '$siteOrigin$pathOrUrl';
    final hit = _cache[url];
    if (!fresh && hit != null && DateTime.now().difference(hit.$1) < _ttl) return hit.$2;
    try {
      final res = await _http.get(Uri.parse(url), headers: {
        'Accept': 'text/markdown',
        'User-Agent': 'DailyAdsApp/1.0 (Android)',
      }).timeout(const Duration(seconds: 20));
      if (res.statusCode == 404) throw SiteException('This page is no longer available.');
      if (res.statusCode >= 400) throw SiteException('DailyAds.pk is not responding (${res.statusCode}). Please try again.');
      final body = utf8Body(res);
      _cache[url] = (DateTime.now(), body);
      return body;
    } on SocketException {
      throw SiteException('No internet connection. Check your connection and try again.');
    } on TimeoutException {
      throw SiteException('The request timed out. Please try again.');
    } on http.ClientException {
      throw SiteException('Could not reach DailyAds.pk. Please try again.');
    }
  }

  static String utf8Body(http.Response res) => utf8.decode(res.bodyBytes, allowMalformed: true);

  /// Fetches one page of a listing path, e.g. `/category/jobs`.
  Future<AdListPage> listing(String path, {int page = 1, bool fresh = false}) async {
    final sep = path.contains('?') ? '&' : '?';
    final url = page <= 1 ? path : '$path${sep}page=$page';
    return parseListing(await _get(url, fresh: fresh));
  }

  Future<AdDetail> detail(String url) async => parseDetail(await _get(url), url);

  Future<String?> latestDate({bool fresh = false}) async => parseLatestDate(await _get('/', fresh: fresh));

  Future<List<Newspaper>> newspapers() async => parseNewspapers(await _get('/newspaper/dawn'));

  static String searchPath(String query) =>
      '/archive/search/${Uri.encodeComponent(query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))}';
}
