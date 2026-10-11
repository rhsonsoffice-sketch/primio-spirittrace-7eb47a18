import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/investigation_provider.dart';
import '../providers/past_investigations_provider.dart';
import '../providers/trace_memory_provider.dart';
import '../repositories/investigation_repository.dart';
import '../screens/home_screen.dart';
import '../screens/investigation_detail_screen.dart';
import '../screens/investigation_screen.dart';
import '../screens/investigation_summary_screen.dart';
import '../screens/past_investigations_screen.dart';
import '../screens/settings_screen.dart';
import '../services/audio_service.dart';
import '../services/investigation_service.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final repo = context.read<InvestigationRepository>();
          return MultiProvider(
            providers: [
              Provider(create: (_) => InvestigationService(repository: repo)),
              ChangeNotifierProvider(
                create: (ctx) => TraceMemoryProvider(
                  service: ctx.read<InvestigationService>(),
                )..load(),
              ),
            ],
            child: const HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: '/investigation',
        pageBuilder: (context, state) {
          final repo = context.read<InvestigationRepository>();
          return CustomTransitionPage(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 520),
            transitionsBuilder: (context, animation, secondary, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
                  child: child,
                ),
              );
            },
            child: MultiProvider(
              providers: [
                Provider(create: (_) => InvestigationService(repository: repo)),
                Provider(create: (_) => AudioService()),
                ChangeNotifierProvider(
                  create: (ctx) => InvestigationProvider(
                    service: ctx.read<InvestigationService>(),
                    audioService: ctx.read<AudioService>(),
                  )..initAudio(),
                ),
              ],
              child: const InvestigationScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/past-investigations',
        builder: (context, state) {
          final repo = context.read<InvestigationRepository>();
          return MultiProvider(
            providers: [
              Provider(create: (_) => InvestigationService(repository: repo)),
              ChangeNotifierProvider(
                create: (ctx) => PastInvestigationsProvider(
                  service: ctx.read<InvestigationService>(),
                )..load(),
              ),
            ],
            child: const PastInvestigationsScreen(),
          );
        },
      ),
      GoRoute(
        path: '/investigation-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final repo = context.read<InvestigationRepository>();
          return MultiProvider(
            providers: [
              Provider(create: (_) => InvestigationService(repository: repo)),
              ChangeNotifierProvider(
                create: (ctx) => PastInvestigationsProvider(
                  service: ctx.read<InvestigationService>(),
                )..load(),
              ),
            ],
            child: InvestigationDetailScreen(investigationId: id),
          );
        },
      ),
      GoRoute(
        path: '/investigation-summary/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final repo = context.read<InvestigationRepository>();
          return MultiProvider(
            providers: [
              Provider(create: (_) => InvestigationService(repository: repo)),
              ChangeNotifierProvider(
                create: (ctx) => PastInvestigationsProvider(
                  service: ctx.read<InvestigationService>(),
                )..load(),
              ),
            ],
            child: InvestigationSummaryScreen(investigationId: id),
          );
        },
      ),
    ],
  );
}
