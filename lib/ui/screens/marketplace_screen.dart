import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/marketplace_listing.dart';
import '../../models/widget_type.dart';
import '../../state/app_state.dart';
import '../components/widget_preview.dart';
import 'listing_detail_screen.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketplaceState>();
    final listings = market.visible;

    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Marketplace')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search widgets, tags…',
              leading: const Icon(Icons.search),
              onChanged: market.setQuery,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: market.typeFilter == null,
                  onSelected: (_) => market.setTypeFilter(null),
                ),
                for (final t in WidgetType.values)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(t.label),
                      selected: market.typeFilter == t,
                      onSelected: (sel) => market.setTypeFilter(sel ? t : null),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (market.loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (listings.isEmpty)
          const SliverFillRemaining(child: Center(child: Text('No widgets match your search.')))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList.separated(
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ListingCard(listing: listings[i]),
            ),
          ),
      ],
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final MarketplaceListing listing;

  @override
  Widget build(BuildContext context) {
    final installed = context.select<MyWidgetsState, bool>((s) => s.isInstalled(listing.id));
    final text = Theme.of(context).textTheme;
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetPreview(type: listing.type, config: listing.config, compact: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text(listing.name, style: text.titleMedium)),
                  if (installed) const Icon(Icons.check_circle, size: 20),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${listing.author} · ${listing.type.label} · ${listing.downloads} downloads',
                style: text.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(listing.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
