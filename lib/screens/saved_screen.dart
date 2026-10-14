import 'package:flutter/material.dart';

import '../data/saved_store.dart';
import '../widgets/ad_card.dart';
import '../widgets/states.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved ads')),
      body: ListenableBuilder(
        listenable: SavedStore.instance,
        builder: (context, _) {
          final saved = SavedStore.instance.saved;
          if (saved.isEmpty) {
            return const MessageView(
              icon: Icons.bookmark_border,
              title: 'No saved ads yet',
              message: 'Tap the bookmark on any advertisement to keep it here. Saved ads stay on this phone.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: saved.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => AdCard(saved[i]),
          );
        },
      ),
    );
  }
}
