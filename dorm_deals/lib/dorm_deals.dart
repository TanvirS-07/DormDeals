import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/widgets/listings_list.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/theme.dart';
import 'package:dorm_deals/widgets/new_listing.dart';

class DormDeals extends StatefulWidget {
  const DormDeals({super.key, this.loadListingsOnStart = true});

  final bool loadListingsOnStart;

  @override
  State<DormDeals> createState() {
    return _DormDealsState();
  }
}

class _DormDealsState extends State<DormDeals> {
  final _searchController = TextEditingController();
  ItemCategory? _categoryFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    if (!widget.loadListingsOnStart) {
      return;
    }

    // Delay the initial load until after the first build so Provider is available from context.
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      Provider.of<ListingState>(context, listen: false).loadListings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddListingOverlay() {
    showListingEditor(context);
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _categoryFilter = null;
    });
  }

  List<Listing> _filtered(List<Listing> listings) {
    final query = _searchQuery.trim().toLowerCase();

    return listings.where((listing) {
      if (_categoryFilter != null && listing.category != _categoryFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return listing.title.toLowerCase().contains(query) ||
          listing.description.toLowerCase().contains(query) ||
          listing.pickupLocation.toLowerCase().contains(query);
    }).toList();
  }

  Widget _boardHeader(BuildContext context, int total) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The board', style: textTheme.displaySmall),
          const SizedBox(height: 6),
          Text(
            total == 1
                ? '1 thing for sale on campus right now.'
                : '$total things for sale on campus right now.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: TextField(
              key: const ValueKey('search-field'),
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search listings',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _filterChip(null, 'All'),
                for (final category in ItemCategory.values)
                  _filterChip(category, category.label),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(ItemCategory? category, String label) {
    final selected = _categoryFilter == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) {
          setState(() {
            _categoryFilter = category;
          });
        },
        avatar: category == null
            ? null
            : Icon(
                categoryIcons[category],
                size: 16,
                color: selected ? Colors.white : AppColors.inkMuted,
              ),
        label: Text(label),
      ),
    );
  }

  Widget _centeredMessage({
    required Widget icon,
    required String title,
    required String body,
    required Widget action,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 24),
              action,
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconTile(IconData icon, {Color? color, Color? background}) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: background ?? AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, size: 34, color: color ?? AppColors.accent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingState = Provider.of<ListingState>(context);
    final myListings = listingState.listings;
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    // Chooses the main screen content based on the current Firestore loading state.
    Widget bodyContent;

    if (listingState.isLoading) {
      bodyContent = const _LoadingBoard();
    } else if (listingState.errorMessage != null) {
      bodyContent = _centeredMessage(
        icon: _iconTile(
          Icons.cloud_off_outlined,
          color: AppColors.danger,
          background: AppColors.dangerSoft,
        ),
        title: 'Can\'t reach the board',
        body: listingState.errorMessage!,
        action: ElevatedButton.icon(
          onPressed: () {
            listingState.loadListings();
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Try Again'),
        ),
      );
    } else if (myListings.isEmpty) {
      bodyContent = _centeredMessage(
        icon: _iconTile(Icons.storefront_outlined),
        title: 'No listings yet!',
        body: 'Be the first to post a listing.',
        action: ElevatedButton.icon(
          key: const ValueKey('empty-state-add-listing-button'),
          onPressed: _openAddListingOverlay,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Listing'),
        ),
      );
    } else {
      final visibleListings = _filtered(myListings);

      bodyContent = RefreshIndicator(
        onRefresh: listingState.loadListings,
        child: ListingsList(
          allListings: visibleListings,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _boardHeader(context, myListings.length),
              if (visibleListings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 32,
                          color: AppColors.inkFaint,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nothing matches that yet.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/images/dorm_deals_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('DormDeals'),
          ],
        ),
        actions: [
          if (isPhone)
            IconButton.filled(
              key: const ValueKey('appbar-add-listing-button'),
              tooltip: 'Sell something',
              onPressed: _openAddListingOverlay,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
            )
          else
            FilledButton.icon(
              key: const ValueKey('appbar-add-listing-button'),
              onPressed: _openAddListingOverlay,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Sell something'),
            ),
          const SizedBox(width: 4),
          IconButton(
            key: const ValueKey('logout-button'),
            tooltip: 'Log out',
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout, size: 22),
          ),
          const SizedBox(width: 12),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: bodyContent,
    );
  }
}

// Placeholder cards shaped like the real ones, pulsing while Firestore loads.
class _LoadingBoard extends StatefulWidget {
  const _LoadingBoard();

  @override
  State<_LoadingBoard> createState() => _LoadingBoardState();
}

class _LoadingBoardState extends State<_LoadingBoard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.sunken,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 190, color: AppColors.sunken),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(80, 18),
                const SizedBox(height: 14),
                _bar(200, 16),
                const SizedBox(height: 10),
                _bar(double.infinity, 12),
                const SizedBox(height: 6),
                _bar(150, 12),
                const SizedBox(height: 18),
                _bar(120, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.55, end: 1.0).animate(_pulse),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sidePadding = constraints.maxWidth > maxContentWidth + 40
              ? (constraints.maxWidth - maxContentWidth) / 2
              : 20.0;
          final contentWidth = constraints.maxWidth - sidePadding * 2;
          final columns = contentWidth >= 960
              ? 3
              : contentWidth >= 600
              ? 2
              : 1;

          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(220, 36),
                const SizedBox(height: 12),
                _bar(280, 16),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < columns; i++) ...[
                      if (i > 0) const SizedBox(width: 16),
                      Expanded(child: _card()),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
