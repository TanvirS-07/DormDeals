import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/firebase_options.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/theme.dart';
import 'package:dorm_deals/widgets/auth_widget.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ListingState(),
      child: MaterialApp(
        title: 'DormDeals',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthWidget(),
      ),
    ),
  );
}
