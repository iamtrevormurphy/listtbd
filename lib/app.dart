import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/theme_config.dart';
import 'main.dart' show preferencesService;
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/lists/all_lists_screen.dart';

class ListApp extends ConsumerWidget {
  const ListApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Provisions',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.lightTheme,
      darkTheme: ThemeConfig.darkTheme,
      themeMode: ThemeMode.light, // Default to light mode
      home: authState.when(
        data: (session) {
          if (session == null) return const LoginScreen();
          // Check if there's a saved list to return to
          if (preferencesService.hasLastList) {
            return const HomeScreen();
          }
          // No saved list - show the lists page
          return const AllListsScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
