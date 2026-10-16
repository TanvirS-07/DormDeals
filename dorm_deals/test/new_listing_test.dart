import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/models/listing.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/widgets/new_listing.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  Widget createTestWidget({Listing? existingListing}) {
    return ChangeNotifierProvider(
      create: (context) => ListingState(firestore: FakeFirebaseFirestore()),
      child: MaterialApp(
        home: Scaffold(body: NewListing(existingListing: existingListing)),
      ),
    );
  }

  Listing createListing() {
    return Listing(
      id: 'listing-1',
      title: 'New Apple Macbook',
      description: 'A Macbook Pro for uni work.',
      price: 450.0,
      category: ItemCategory.electronics,
      pickupLocation: 'MQ Library',
      sellerId: 'seller-1',
      sellerName: 'student123@test.com',
      createdAt: DateTime(2026, 5, 19),
    );
  }

  testWidgets('NewListing shows empty form for a new listing', (tester) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Pickup location'), findsOneWidget);
    expect(find.text('Create Listing'), findsOneWidget);
  });

  testWidgets('NewListing shows validation error for empty form', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Listing'));
    await tester.pump();

    expect(
      find.text('Give your listing a clearer title, like "COMP3130 Notes".'),
      findsOneWidget,
    );
  });

  testWidgets('NewListing fills fields when editing a listing', (tester) async {
    await tester.pumpWidget(createTestWidget(existingListing: createListing()));

    expect(find.text('New Apple Macbook'), findsOneWidget);
    expect(find.text('A Macbook Pro for uni work.'), findsOneWidget);
    expect(find.text('450.00'), findsOneWidget);
    expect(find.text('MQ Library'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);
  });
}
