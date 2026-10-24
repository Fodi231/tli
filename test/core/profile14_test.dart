import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlife/core/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'names accept Cyrillic and reject blanks, controls and excess length',
    () {
      expect(GameState.normalizePlayerName('  Анна   Ли  '), 'Анна Ли');
      expect(GameState.validatePlayerName('  Анна Ли  '), null);
      expect(GameState.validatePlayerName('  '), 'short');
      expect(GameState.validatePlayerName('Я'), 'short');
      expect(GameState.validatePlayerName('Я' * 24), null);
      expect(GameState.validatePlayerName('Я' * 25), 'long');
      expect(GameState.validatePlayerName('Анна\nЛи'), 'characters');
      expect(GameState.validatePlayerName('Анна\u0000'), 'characters');
    },
  );

  test(
    'fresh character saves once and reloads without granting more money',
    () async {
      final g = GameState()..forceOffline = true;
      await g.init();
      expect(g.onboardingComplete, false);
      expect(await g.createCharacter('  Анна   Ли  ', 4), true);
      expect(g.playerName, 'Анна Ли');
      expect(g.avatarIndex, 4);
      expect(g.balance, 1500);
      expect(await g.createCharacter('Другой игрок', 2), false);
      final raw = (await SharedPreferences.getInstance()).getString('save')!;
      expect(jsonDecode(raw)['onboardingComplete'], true);
      g.dispose();
      final reloaded = GameState()..forceOffline = true;
      await reloaded.init();
      expect(reloaded.onboardingComplete, true);
      expect(reloaded.playerName, 'Анна Ли');
      expect(reloaded.avatarIndex, 4);
      expect(reloaded.balance, 1500);
      reloaded.dispose();
    },
  );

  test('0.13 save bypasses registration and preserves finances', () async {
    final old = GameState()..balance = 832.5;
    old.openLumaCard('pearl');
    old.createLumaGoal('Верстак', 3000);
    old.moveLumaGoal(old.luma.goals.single.id, 100);
    final raw = jsonDecode(old.exportSave()) as Map<String, dynamic>;
    raw.remove('onboardingComplete');
    raw.remove('avatarIndex');
    SharedPreferences.setMockInitialValues({'save': jsonEncode(raw)});
    final g = GameState()..forceOffline = true;
    await g.init();
    expect(
      g.onboardingComplete,
      true,
      reason: 'even an unnamed existing save is an existing player',
    );
    expect(g.playerName, '');
    expect(g.balance, old.balance);
    expect(g.luma.style, 'pearl');
    expect(g.luma.goals.single.amount, old.luma.goals.single.amount);
    expect(await g.createCharacter('Повторно', 0), false);
    g.dispose();
    old.dispose();
  });

  test('interrupted setup resumes and invalid names change nothing', () async {
    final g = GameState()..forceOffline = true;
    await g.init();
    g.setLiquidGlass(false);
    expect(await g.createCharacter(' ', 8), false);
    expect(g.playerName, '');
    expect(g.onboardingComplete, false);
    final raw = g.exportSave();
    final restored = GameState();
    expect(restored.importSave(raw), true);
    expect(restored.onboardingComplete, false);
    expect(restored.liquidGlass, false);
    g.dispose();
    restored.dispose();
  });

  test('name edits validate and avatar bounds persist independently', () async {
    final g = GameState();
    expect(await g.createCharacter('Мастер', 12), true);
    expect(g.avatarIndex, 5);
    expect(g.setPlayerName(' '), false);
    expect(g.playerName, 'Мастер');
    expect(g.setPlayerName('  Олег  '), true);
    g.setAvatar(-2);
    expect(g.avatarIndex, 0);
    expect(g.playerName, 'Олег');
    g.dispose();
  });

  test(
    'reset deliberately returns to first launch, then saves that state',
    () async {
      final g = GameState()..forceOffline = true;
      await g.init();
      await g.createCharacter('Мастер', 2);
      await g.resetAll();
      expect(g.onboardingComplete, false);
      expect(g.playerName, '');
      expect(g.avatarIndex, 0);
      expect(g.balance, 1500);
      final copy = GameState();
      expect(copy.importSave(g.exportSave()), true);
      expect(copy.onboardingComplete, false);
      g.dispose();
      copy.dispose();
    },
  );

  test('glass preference survives a reload', () async {
    final g = GameState()..forceOffline = true;
    await g.init();
    g.setLiquidGlass(false);
    final copy = GameState();
    expect(
      copy.importSave(
        (await SharedPreferences.getInstance()).getString('save')!,
      ),
      true,
    );
    expect(copy.liquidGlass, false);
    g.dispose();
    copy.dispose();
  });
}
