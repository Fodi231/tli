import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:techlife/core/admin_auth.dart';
import 'package:techlife/core/ai_service.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/i18n.dart';
import 'package:techlife/core/market/device_catalog.dart';
import 'package:techlife/core/repair/device_profile.dart';
import 'package:techlife/core/repair/repair_session.dart';
import 'package:techlife/ui/repair/workbench_geometry.dart';
import 'repair_economy_test.dart' show finishStep;
import 'repair_session_test.dart' show performStep;

void main() {
  setUp(() {
    I18n.lang = 'ru';
    AiService.resume();
    AiService.customUrl = '';
    AiService.modelOverride = null;
  });
  tearDown(() {
    AiService.client = http.Client();
    AiService.resume();
  });
  test('requested administrator password opens the gate', () {
    AdminAuth.logout();
    expect(AdminAuth.login('TLIF-FT'), isTrue);
    AdminAuth.logout();
    expect(AdminAuth.login('TLIF-ft'), isFalse);
  });
  test(
    'model numbers are conversation, ownership changes only on confirmation',
    () async {
      final gs = GameState()..forceOffline = true;
      addTearDown(gs.dispose);
      final d = gs.openMarketDeal('m01')!;
      await gs.sendToDeal(d, 'У iPhone 13 память 128 ГБ?');
      expect(d.status, 'open');
      expect(d.rounds, 0);
      expect(gs.balance, 1500);
      await gs.sendToDeal(d, 'Предлагаю 190', priceOffer: 190);
      expect(d.status, 'agreed');
      expect(gs.stock, isEmpty);
      expect(gs.balance, 1500);
      expect(gs.confirmDeal(d), isTrue);
      expect(gs.balance, 1310);
      expect(gs.stock.single.fault, 'display');
      expect(gs.stock.single.deviceId, 'iphone13');
      expect(gs.confirmDeal(d), isFalse);
      expect(gs.openMarketDeal('m01'), isNull);
    },
  );
  test('buy repair list and sell consumes one part and pays once', () async {
    final gs = GameState()..forceOffline = true;
    addTearDown(gs.dispose);
    final buy = gs.openMarketDeal('m01')!;
    await gs.sendToDeal(buy, '190');
    expect(gs.confirmDeal(buy), isTrue);
    final item = gs.stock.single;
    final brokenValue = item.resaleValue;
    gs.parts['display'] = 1;
    final order = gs.repairStock(item)!;
    expect(gs.publishListing(item, 400, 'test'), isNull);
    gs.startWorkbench(order.id);
    while (!gs.repairs[order.id]!.finished) {
      finishStep(gs, order.id);
    }
    expect(item.fault, isNull);
    expect(item.repaired, isTrue);
    expect(item.resaleValue, greaterThan(brokenValue));
    expect(gs.balance, 1310);
    expect(gs.parts['display'], 0);
    final l = gs.publishListing(item, 410, 'После замены дисплея');
    expect(l, isNotNull);
    final sell = gs.sellDealFor(item)!;
    await gs.sendToDeal(sell, '410');
    expect(sell.status, 'agreed');
    final duplicate = gs.spawnDeal('sell', item: item);
    await gs.sendToDeal(duplicate, '400');
    expect(gs.confirmDeal(sell), isTrue);
    expect(gs.balance, 1720);
    expect(gs.stock, isEmpty);
    expect(l!.status, 'sold');
    expect(gs.confirmDeal(duplicate), isFalse);
    expect(gs.balance, 1720);
  });
  test(
    'confirmation rechecks balance and serializes saved conversations',
    () async {
      final gs = GameState()..forceOffline = true;
      addTearDown(gs.dispose);
      gs.toggleFavorite('m03');
      final d = gs.openMarketDeal('m03')!;
      await gs.sendToDeal(d, '390');
      gs.balance = 100;
      expect(gs.confirmDeal(d), isFalse);
      expect(gs.stock, isEmpty);
      final restored = GameState();
      addTearDown(restored.dispose);
      expect(restored.importSave(gs.exportSave()), isTrue);
      expect(restored.favorites, contains('m03'));
      final chat = restored.deals.firstWhere((x) => x.id == d.id);
      expect(chat.status, 'agreed');
      expect(chat.busy, isFalse);
      expect(chat.messages.length, d.messages.length);
      restored.balance = 500;
      expect(restored.confirmDeal(chat), isTrue);
      expect(restored.stock.single.fault, 'battery');
    },
  );
  test(
    'Gemini REST request includes model auth conversation and deterministic result',
    () async {
      final gs = GameState()..geminiKey = 'AIza_test_not_a_real_key';
      addTearDown(gs.dispose);
      final d = gs.openMarketDeal('m01')!;
      AiService.client = MockClient((request) async {
        expect(request.url.host, 'generativelanguage.googleapis.com');
        expect(request.url.path, contains('gemini-3.8-flash:generateContent'));
        expect(request.headers['x-goog-api-key'], 'AIza_test_not_a_real_key');
        final body = jsonDecode(request.body);
        expect(
          body['systemInstruction']['parts'][0]['text'],
          contains('iPhone 13'),
        );
        expect(
          body['systemInstruction']['parts'][0]['text'],
          contains('display'),
        );
        expect(jsonEncode(body['contents']), contains('GAME RESULT: agree'));
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'internal', 'thought': true},
                    {'text': 'Договорились, подтверди покупку.'},
                  ],
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      await gs.sendToDeal(d, '190');
      expect(d.status, 'agreed');
      expect(d.messages.last.fallback, isFalse);
      expect(d.messages.last.text, 'Договорились, подтверди покупку.');
      expect(gs.balance, 1500);
      expect(gs.stock, isEmpty);
    },
  );
  test(
    'Gemini HTTP failure has an explicit fallback and clears busy state',
    () async {
      final gs = GameState()..geminiKey = 'AIza_test_not_a_real_key';
      addTearDown(gs.dispose);
      AiService.client = MockClient(
        (r) async =>
            http.Response('{"error":{"message":"quota exceeded"}}', 429),
      );
      final d = gs.openMarketDeal('m05')!;
      await gs.sendToDeal(d, 'Есть дефекты?');
      expect(d.busy, isFalse);
      expect(d.messages.last.fallback, isTrue);
      expect(gs.lastAiError, contains('429'));
      expect(d.status, 'open');
    },
  );
  test(
    'all seven hardware profiles finish every service with model-specific rules',
    () {
      expect(
        repairProfiles.map((p) => p.id).toSet(),
        deviceCatalog.map((d) => d.id).toSet(),
      );
      expect(
        repairProfiles
            .map(
              (p) =>
                  '${p.battery.x}:${p.battery.y}:${p.battery.w}:${p.battery.h}',
            )
            .toSet()
            .length,
        7,
      );
      for (final d in deviceCatalog) {
        for (final service in ['display', 'battery', 'camera', 'port']) {
          final s = RepairSession('x', service, device: d.name);
          final p = profileFor(d.name);
          expect(s.steps.any((x) => x.id == 'frame_out'), p.apple);
          if (p.rearAccess && service == 'display') {
            expect(s.steps.any((x) => x.id == 'flip_front'), isTrue);
          }
          while (!s.finished) {
            performStep(s);
          }
          expect(s.mistakes, 0);
          expect(s.batteryDisconnected, isFalse);
          expect(RepairSession.fromJson(s.toJson()).device, d.name);
        }
      }
    },
  );
  test('every model action and drop zone uses the rendered geometry', () {
    for (final model in deviceCatalog) {
      for (final service in ['display', 'battery', 'camera', 'port']) {
        for (final wide in [false, true]) {
          final s = RepairSession(
            'test',
            service,
            device: model.name,
            training: true,
          );
          final g = WorkbenchGeometry(wide);
          while (!s.finished) {
            final step = s.current!;
            for (final target in step.targets) {
              expect(
                g.hit(g.rect(target, s).center, s, .6),
                target,
                reason: '${model.id} ${step.id} $target',
              );
              if (step.destination != null) {
                expect(
                  g.dropZone(g.rect(step.destination!, s).center, s),
                  step.destination,
                );
              }
            }
            performStep(s);
          }
        }
      }
    }
  });
  test(
    'v1 save migrates Android step ids instead of replaying the wrong index',
    () {
      final old = RepairSession('old', 'battery');
      while (old.current!.id != 'battery_off') {
        performStep(old);
      }
      final data =
          old.toJson()
            ..['v'] = 1
            ..['device'] = 'Galaxy S22';
      final migrated = RepairSession.fromJson(data);
      expect(migrated.current!.id, 'battery_off');
      expect(migrated.device, 'Galaxy S22');
    },
  );
}
