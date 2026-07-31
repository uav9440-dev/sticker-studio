import 'package:go_router/go_router.dart';

import 'package:sticker_studio_ai/features/ai/presentation/ai_screen.dart';
import 'package:sticker_studio_ai/features/billing/presentation/paywall_screen.dart';
import 'package:sticker_studio_ai/features/editor/presentation/editor_screen.dart';
import 'package:sticker_studio_ai/features/home/home_screen.dart';
import 'package:sticker_studio_ai/features/library/presentation/library_screen.dart';
import 'package:sticker_studio_ai/features/templates/presentation/templates_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/editor', builder: (_, __) => const EditorScreen()),
    GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
    GoRoute(path: '/templates', builder: (_, __) => const TemplatesScreen()),
    GoRoute(path: '/ai', builder: (_, __) => const AiScreen()),
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
  ],
);
