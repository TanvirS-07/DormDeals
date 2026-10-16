import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/theme.dart';
import 'package:dorm_deals/widgets/new_listing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListingItem extends StatefulWidget {
  const ListingItem({super.key, required this.eachListing, this.currentUserId});

  final Listing eachListing;
  final String? currentUserId;

  @override
  State<ListingItem> createState() => _ListingItemState();
}

class _ListingItemState extends State<ListingItem> {
  bool _isHovered = false;

  Listing get eachListing => widget.eachListing;

  void _launchMaps() async {
    final latitude = eachListing.latitude;
    final longitude = eachListing.longitude;

    if (latitude == null || longitude == null) {
      return;
    }

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    await launchUrl(googleMapsUrl);
  }

  void _confirmDeleteListing(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this listing?'),
        content: Text(
          '"${eachListing.title}" will be removed from the board for everyone. '
          'This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.inkMuted),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () async {
              final listingState = Provider.of<ListingState>(
                context,
                listen: false,
              );
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);

              try {
                await listingState.deleteListing(eachListing);

                if (!dialogContext.mounted) return;
                navigator.pop();

                messenger.showSnackBar(
                  const SnackBar(content: Text('Listing deleted.')),
                );
              } catch (error) {
                if (!dialogContext.mounted) return;
                navigator.pop();

                messenger.showSnackBar(
                  SnackBar(content: Text('Could not delete listing: $error')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _photo(BuildContext context) {
    final placeholder = Container(
      color: AppColors.accentSoft,
      alignment: Alignment.center,
      child: Icon(
        categoryIcons[eachListing.category],
        size: 44,
        color: AppColors.accent.withValues(alpha: 0.55),
      ),
    );

    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (eachListing.image == null)
            placeholder
          else
            AnimatedScale(
              scale: _isHovered ? 1.03 : 1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              child: Image.network(
                eachListing.image!,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
            ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: softShadow,
              ),
              child: Text(
                '\$${eachListing.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.3,
                  color: AppColors.ink,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.inkFaint),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }

  Widget _ownerActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit listing',
          visualDensity: VisualDensity.compact,
          onPressed: () {
            showListingEditor(context, existingListing: eachListing);
          },
          icon: const Icon(Icons.edit, size: 19),
        ),
        IconButton(
          tooltip: 'Delete listing',
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: () {
            _confirmDeleteListing(context);
          },
          icon: const Icon(Icons.delete, size: 19),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final signedInUserId =
        widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    // Only the seller who created the listing can see edit and delete actions.
    final isOwner = signedInUserId == eachListing.sellerId;
    final hasCoordinates =
        eachListing.latitude != null && eachListing.longitude != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.hairline),
          boxShadow: _isHovered ? softShadow : const [],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _photo(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcons[eachListing.category],
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          eachListing.category.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _postedAgo(eachListing.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eachListing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eachListing.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _metaRow(
                    Icons.location_on_outlined,
                    eachListing.pickupLocation,
                  ),
                  const SizedBox(height: 6),
                  _metaRow(Icons.person_outline, eachListing.sellerName),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Spacer(),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    if (hasCoordinates)
                      TextButton.icon(
                        onPressed: _launchMaps,
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: const Text('View on Map'),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Pickup on campus',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (isOwner) _ownerActions(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _postedAgo(DateTime createdAt) {
  final age = DateTime.now().difference(createdAt);

  if (age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes}m ago';
  if (age.inDays < 1) return '${age.inHours}h ago';
  if (age.inDays < 7) return '${age.inDays}d ago';
  if (age.inDays < 60) return '${age.inDays ~/ 7}w ago';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${createdAt.day} ${months[createdAt.month - 1]}';
}
