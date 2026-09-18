import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'di/injection.dart';

class HesablyApp extends StatefulWidget {
  final AuthCubit? authCubit;
  final AppRouter? _router;

  const HesablyApp({super.key, this.authCubit, AppRouter? router}) : _router = router;

  @override
  State<HesablyApp> createState() => _HesablyAppState();
}

class _HesablyAppState extends State<HesablyApp> {
  late final AuthCubit _authCubit;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authCubit = widget.authCubit ?? getIt<AuthCubit>();
    _appRouter = widget._router ?? AppRouter(_authCubit);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: MaterialApp.router(
        title: 'Hesably',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _appRouter.router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
      ),
    );
  }
}
