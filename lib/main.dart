import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/game_state.dart';
import 'core/theme.dart';
import 'ui/phone_shell.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
      title: 'TechLife',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const PhoneShell(),
    );
  }
}
