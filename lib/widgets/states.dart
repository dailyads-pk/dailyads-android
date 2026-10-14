import 'package:flutter/material.dart';

import '../theme.dart';

class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 48, color: Sheet.text3),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: Sheet.text2)),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel ?? 'Try again')),
            ],
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView(this.error, {super.key, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MessageView(
        icon: Icons.cloud_off_outlined,
        title: 'Couldn’t load ads',
        message: error.toString(),
        onAction: onRetry,
      );
}
