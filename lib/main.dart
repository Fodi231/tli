import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_info.dart';
import 'core/app_log.dart';
import 'core/game_state.dart';
import 'core/theme.dart';
import 'core/window_service.dart';
import 'ui/phone_shell.dart';
import 'ui/onboarding.dart';
import 'ui/system_notice.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Every uncaught error ends up in the admin panel log.
  FlutterError.onError = (details) {
    AppLog.I.error('app', details.exceptionAsString());
    FlutterError.presentError(details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    AppLog.I.error('app', error.toString());
    return true;
  };

  // On phones the game draws its own clock/battery, so hide the system bars
  // (status bar on iOS and Android, navigation buttons on Android).
  final isPhone =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  if (isPhone) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // The repair bench supports both portrait and landscape on phones too.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  final gs = GameState();
  await gs.init();
  // Desktop: window title, size and full screen from the saved settings.
  await WinService.init(
    w: gs.winW,
    h: gs.winH,
    fullscreen: gs.fullscreen,
    title: kAppName,
  );
  AppLog.I.info('app', 'запуск $kAppName $kAppVersion');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<GameState>.value(value: gs),
        ChangeNotifierProvider<Shell>(create: (_) => Shell()),
      ],
      child: const TechLifeApp(),
    ),
  );
}

class TechLifeApp extends StatefulWidget {
  const TechLifeApp({super.key});
  @override
  State<TechLifeApp> createState() => _TechLifeAppState();
}

class _TechLifeAppState extends State<TechLifeApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The device switched between light and dark: matters for the "system" theme.
  @override
  void didChangePlatformBrightness() {
    if (mounted) context.read<GameState>().refreshTheme();
  }

  @override
  Widget build(BuildContext context) {
    final scale = context.select<GameState, double>((g) => g.textScale);
    final ui = context.select<GameState, int>((g) => g.uiScalePct) / 100.0;
    final mode = context.select<GameState, int>((g) => g.themeMode);
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode:
          mode == 0
              ? ThemeMode.system
              : mode == 1
              ? ThemeMode.light
              : ThemeMode.dark,
      builder: (context, child) {
        final mq = MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale));
        Widget app = child!;
        if ((ui - 1.0).abs() > 0.01) {
          // Interface scale: lay out in a smaller virtual window and magnify it.
          final vw = mq.size.width / ui;
          final vh = mq.size.height / ui;
          app = ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: vw,
              maxWidth: vw,
              minHeight: vh,
              maxHeight: vh,
              child: Transform.scale(
                scale: ui,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: vw,
                  height: vh,
                  child: MediaQuery(
                    data: mq.copyWith(size: Size(vw, vh)),
                    child: app,
                  ),
                ),
              ),
            ),
          );
        }
        // F11 = full screen, Esc = leave full screen (Windows / Linux / macOS).
        if (WinService.isDesktop) {
          app = CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.f11): () {
                final g = context.read<GameState>();
                g.setFullscreen(!g.fullscreen);
              },
              const SingleActivator(LogicalKeyboardKey.escape): () {
                final g = context.read<GameState>();
                if (g.fullscreen) g.setFullscreen(false);
              },
            },
            child: Focus(autofocus: true, child: app),
          );
        }
        return MediaQuery(data: mq, child: SystemNoticeHost(child: app));
      },
      home: const GameEntry(),
    );
  }
}

/// Existing saves bypass registration; a reset returns to the introduction.
class GameEntry extends StatelessWidget {
  const GameEntry({super.key});
  @override
  Widget build(BuildContext context) {
    final g = context.watch<GameState>();
    if (!g.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return g.onboardingComplete ? const PhoneShell() : const OnboardingScreen();
  }
}
