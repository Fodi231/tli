import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/core/repair/repair_strings.dart';
import 'package:techlife/ui/phone_shell.dart';
import 'package:techlife/ui/repair/repair_bench.dart';
import 'package:techlife/ui/shell.dart';

void main() {
  testWidgets(
    'bench opens full screen in forced phone and light modes, then returns to orders',
    (tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      I18n.lang = 'uk';
      final gs =
          GameState()
            ..layoutMode = 1
            ..themeMode = 1;
      final shell = Shell()..open('repair', arg: RepairSession.practiceId);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GameState>.value(value: gs),
            ChangeNotifierProvider<Shell>.value(value: shell),
          ],
          child: const MaterialApp(home: PhoneShell()),
        ),
      );
      await tester.pump();
      expect(find.byType(WorkbenchView), findsOneWidget);
      expect(find.byType(PhoneScreen), findsNothing);
      await tester.tap(find.byTooltip(rt('r_exit')));
      await tester.pump();
      expect(find.byType(WorkbenchView), findsNothing);
      expect(find.byType(PhoneScreen), findsOneWidget);
      expect(find.text(rt('r_training')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      gs.dispose();
      shell.dispose();
    },
  );
}
