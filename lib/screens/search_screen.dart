import 'package:flutter/material.dart';

import '../data/saved_store.dart';
import '../data/site_client.dart';
import '../theme.dart';
import '../widgets/paged_ad_list.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _query;
  AdType? _type;

  static const _suggestions = ['teacher jobs', 'PPSC', 'bank jobs', 'construction tender', 'university admission', 'Pak Army', 'auction', 'result'];

  void _submit(String q) {
    final v = q.trim();
    if (v.isEmpty) return;
    _controller.text = v;
    _focus.unfocus();
    SavedStore.instance.addRecentSearch(v);
    setState(() => _query = v);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            decoration: InputDecoration(
              hintText: 'Search jobs, tenders, organisations…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isEmpty && _query == null
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = null);
                        _focus.requestFocus();
                      },
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (_query != null)
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: const Text('All types'), selected: _type == null, onSelected: (_) => setState(() => _type = null)),
                ),
                for (final t in AdType.all)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t.label),
                      selected: _type == t,
                      selectedColor: t.bg,
                      onSelected: (_) => setState(() => _type = _type == t ? null : t),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(child: _query == null ? _idle(context) : _results()),
      ]),
    );
  }

  Widget _results() {
    final base = SiteClient.searchPath(_query!);
    final path = _type == null ? base : '$base/category/${_type!.slug}';
    return PagedAdList(
      key: ValueKey(path),
      path: path,
      fallbackType: _type,
      emptyTitle: 'No ads match “$_query”',
      emptyMessage: 'Try fewer or different words.',
      header: (context, summary) => summary == null ? const SizedBox.shrink() : Text(summary, style: const TextStyle(color: Sheet.text2)),
    );
  }

  Widget _idle(BuildContext context) {
    return ListenableBuilder(
      listenable: SavedStore.instance,
      builder: (context, _) {
        final recent = SavedStore.instance.recentSearches;
        return ListView(padding: const EdgeInsets.all(16), children: [
          if (recent.isNotEmpty) ...[
            Row(children: [
              Text('Recent searches', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton(onPressed: SavedStore.instance.clearRecentSearches, child: const Text('Clear')),
            ]),
            for (final r in recent)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: Sheet.text3),
                title: Text(r),
                onTap: () => _submit(r),
              ),
            const SizedBox(height: 16),
          ],
          Text('Popular searches', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in _suggestions) ActionChip(label: Text(s), onPressed: () => _submit(s)),
          ]),
        ]);
      },
    );
  }
}
