import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/firebase_options.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/theme.dart';
import 'package:dorm_deals/widgets/auth_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Run with --dart-define=USE_EMULATORS=true to talk to the local Firebase
// emulators instead of the live project (see README, "Running locally").
const useEmulators = bool.fromEnvironment('USE_EMULATORS');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useEmulators) {
    // The Android emulator reaches the host machine through 10.0.2.2.
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : 'localhost';

    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    if (kIsWeb) {
      // A saved web session gets restored against the live project before the
      // emulator is wired up, which signs you out and breaks the next login.
      // Keeping the session in memory avoids that, so log in once per page load.
      await FirebaseAuth.instance.setPersistence(Persistence.NONE);
    }
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }

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
