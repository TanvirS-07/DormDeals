import 'package:flutter/material.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/widgets/listing_item.dart';

const maxContentWidth = 1160.0;

class ListingsList extends StatelessWidget {
  const ListingsList({super.key, required this.allListings, this.header});

  final List<Listing> allListings;
  final Widget? header;

  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap the content width on big monitors but keep the whole page scrollable.
        final sidePadding = constraints.maxWidth > maxContentWidth + 40
            ? (constraints.maxWidth - maxContentWidth) / 2
            : 20.0;
        final contentWidth = constraints.maxWidth - sidePadding * 2;

        // One column on phones, then grow to two or three cards per row.
        final columns = contentWidth >= 960
            ? 3
            : contentWidth >= 600
            ? 2
            : 1;
        final rowCount = (allListings.length / columns).ceil();
        final headerCount = header == null ? 0 : 1;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(sidePadding, 4, sidePadding, 48),
          itemCount: rowCount + headerCount,
          itemBuilder: (listContext, index) {
            if (header != null && index == 0) {
              return header!;
            }

            final start = (index - headerCount) * columns;

            // IntrinsicHeight lets every card in a row stretch to the tallest one,
            // so the map/edit footers line up.
            return Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: start + column < allListings.length
                            ? ListingItem(
                                key: ValueKey(allListings[start + column].id),
                                eachListing: allListings[start + column],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
