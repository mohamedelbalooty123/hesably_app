import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import 'go_router_refresh_stream.dart';

/// Centralized GoRouter route table.
///
/// The app shell hosts four destinations (Home, Transactions, Reports,
/// Settings) using an indexed-stack shell that preserves each tab's stack.
/// Auth and onboarding gates are handled by the [redirect] method.
class AppRouter {
  AppRouter(this.authCubit) {
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: _redirect,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OtpVerificationScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            _shellBranch('/home', const _HomeScreen()),
            _shellBranch('/transactions', const _TransactionsScreen()),
            _shellBranch('/reports', const _ReportsScreen()),
            _shellBranch('/settings', const _SettingsScreen()),
          ],
        ),
      ],
    );
  }

  final AuthCubit authCubit;
  late final GoRouter _router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = authCubit.state;
    final isSplash = state.uri.path == '/splash';
    final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/otp';

    if (authState is AuthInitial) {
      return isSplash ? null : '/splash';
    }

    if (authState is AuthUnauthenticated) {
      return isLoggingIn ? null : '/login';
    }

    if (authState is AuthOtpSent) {
      return state.uri.path == '/otp' ? null : '/otp';
    }

    if (authState is AuthAuthenticated) {
      return (isSplash || isLoggingIn) ? '/home' : null;
    }

    // In AuthLoading, AuthFailure we stay where we are.
    return null;
  }

  static StatefulShellBranch _shellBranch(String path, Widget screen) {
    return StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          pageBuilder: (context, state) => NoTransitionPage(child: screen),
        ),
      ],
    );
  }

  GoRouter get router => _router;
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navTransactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart),
            label: l10n.navReports,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}

class _SectionScreen extends StatelessWidget {
  const _SectionScreen({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(l10n.placeholderMessage),
          ],
        ),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) => _SectionScreen(
    title: AppLocalizations.of(context).navHome,
    icon: Icons.home,
  );
}

class _TransactionsScreen extends StatelessWidget {
  const _TransactionsScreen();

  @override
  Widget build(BuildContext context) => _SectionScreen(
    title: AppLocalizations.of(context).navTransactions,
    icon: Icons.receipt_long,
  );
}

class _ReportsScreen extends StatelessWidget {
  const _ReportsScreen();

  @override
  Widget build(BuildContext context) => _SectionScreen(
    title: AppLocalizations.of(context).navReports,
    icon: Icons.bar_chart,
  );
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen();

  @override
  Widget build(BuildContext context) => _SectionScreen(
    title: AppLocalizations.of(context).navSettings,
    icon: Icons.settings,
  );
}
