import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/service_providers.dart';
import 'firebase/firebase_configuration.dart';
import 'services/firebase_initialization_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseEnabled =
      FirebaseConfiguration.enabled ||
      (FirebaseConfiguration.detectAndroidConfig &&
          await FirebaseInitializationService.hasAndroidConfig());
  runApp(
    ProviderScope(
      overrides: [firebaseEnabledProvider.overrideWithValue(firebaseEnabled)],
      child: const LabApp(),
    ),
  );
}
