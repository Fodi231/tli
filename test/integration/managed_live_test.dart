import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/io_client.dart';
import 'package:techlife/core/ai_service.dart';
import 'package:techlife/core/game_state.dart';

void main() {
  test(
    'new player real server AI with no API key',
    () async {
      AiService.client = IOClient(
        HttpClient()..findProxy = HttpClient.findProxyFromEnvironment,
      );
      AiService.managedEnabled = true;
      AiService.customUrl = '';
      AiService.resume();
      final gs = GameState();
      try {
        expect(gs.aiKey, isEmpty);
        final ping = await gs.adminTestAi();
        print(
          'MANAGED_LIVE ${jsonEncode({'stage': 'ping', 'ok': ping.ok, 'text': ping.text, 'error': ping.error, 'ms': ping.ms})}',
        );
        expect(ping.ok, isTrue);
        final d = gs.openMarketDeal('m01')!;
        await gs.sendToDeal(d, 'Какая поломка у iPhone 13 и сколько памяти?');
        print(
          'MANAGED_LIVE ${jsonEncode({'stage': 'question', 'fallback': d.messages.last.fallback, 'text': d.messages.last.text, 'ms': gs.lastAiMs, 'error': gs.lastAiError})}',
        );
        expect(d.messages.last.fallback, isFalse);
        await gs.sendToDeal(d, 'Предлагаю 190 долларов.', priceOffer: 190);
        print(
          'MANAGED_LIVE ${jsonEncode({'stage': 'offer', 'fallback': d.messages.last.fallback, 'text': d.messages.last.text, 'status': d.status, 'balance': gs.balance, 'owned': gs.stock.length})}',
        );
        expect(d.messages.last.fallback, isFalse);
        expect(d.status, 'agreed');
        expect(gs.stock, isEmpty);
        expect(gs.balance, 1500);
      } finally {
        gs.dispose();
        AiService.client.close();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: Platform.environment['RUN_LIVE_AI'] != '1',
  );
}
