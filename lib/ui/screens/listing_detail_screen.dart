import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_listing.dart';
import '../../state/app_state.dart';
import '../components/widget_preview.dart';
import 'widget_editor_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final MarketplaceListing listing;

  Future<void> _install(BuildContext context) async {
    final myWidgets = context.read<MyWidgetsState>();
    final market = context.read<MarketplaceState>();
    final navigator = Navigator.of(context);
    final widget = await myWidgets.install(listing);
    await market.recordDownload(listing);
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => WidgetEditorScreen(widgetId: widget.id)),
    );
  }

  Future<void> _unpublish(BuildContext context) async {
    final market = context.read<MarketplaceState>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from marketplace?'),
        content: const Text('Your installed copy stays in My Widgets.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      await market.unpublish(listing.id);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = context.select<MyWidgetsState, bool>((s) => s.isInstalled(listing.id));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(listing.type.label),
        actions: [
          if (listing.source == ListingSource.user)
            IconButton(
              tooltip: 'Remove from marketplace',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _unpublish(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WidgetPreview(type: listing.type, config: listing.config),
          const SizedBox(height: 20),
          Text(listing.name, style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('by ${listing.author} · ${listing.downloads} downloads', style: text.bodyMedium),
          const SizedBox(height: 16),
          Text(listing.description, style: text.bodyLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in listing.tags) Chip(label: Text('#$t'))],
          ),
          const SizedBox(height: 16),
          Text(
            'After downloading you can edit every setting of this widget.',
            style: text.bodySmall,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: Icon(installed ? Icons.add : Icons.download),
            label: Text(installed ? 'Get another copy' : 'Get widget'),
            onPressed: () => _install(context),
          ),
        ),
      ),
    );
  }
}
