import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/paged_ad_list.dart';

class ListingScreen extends StatelessWidget {
  const ListingScreen({super.key, required this.title, required this.path, this.type});
  final String title;
  final String path;
  final AdType? type;

  static Route<void> route(String title, String path, {AdType? type}) =>
      MaterialPageRoute(builder: (_) => ListingScreen(title: title, path: path, type: type));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PagedAdList(
        path: path,
        fallbackType: type,
        header: (context, summary) => summary == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(summary, style: const TextStyle(color: Sheet.text2)),
              ),
      ),
    );
  }
}
