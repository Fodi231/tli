import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/app_info.dart';
import 'core/app_log.dart';
import 'core/game_state.dart';
import 'core/theme.dart';
import 'ui/phone_shell.dart';
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
  final isPhone = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  if (isPhone) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  final gs = GameState();
  await gs.init();
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
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const PhoneShell(),
    );
  }
}
