import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';

/// Global preferences service instance
final preferencesService = PreferencesService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize preferences service
  await preferencesService.initialize();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize notification service
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: ListApp(),
    ),
  );
}
