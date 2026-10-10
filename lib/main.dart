import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/game_state.dart';
import 'core/theme.dart';
import 'ui/phone_shell.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class TechLifeApp extends StatelessWidget {
  const TechLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = context.select<GameState, double>((g) => g.textScale);
    return MaterialApp(
      title: 'TechLife',
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
