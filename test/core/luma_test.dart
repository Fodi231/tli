import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/core/catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameState g;
  setUp(() => g = GameState());
  tearDown(() => g.dispose());
  void day() {
    for (var i = 0; i < 30; i++) {
      g.advanceLumaClockForTest();
    }
  }

  test(
    'opening or reopening cannot create money; paid styles charged once',
    () {
      expect(g.openLumaCard('gold'), false);
      expect(g.openLumaCard('classic'), true);
      expect(g.openLumaCard('classic'), false);
      expect(g.balance, 1500);
      expect(g.buyLumaStyle('gold'), true);
      expect(g.balance, 1440);
      expect(g.buyLumaStyle('pearl'), true);
      expect(g.buyLumaStyle('gold'), true);
      expect(g.balance, 1440);
      expect(g.closeLumaCard(), true);
      expect(g.openLumaCard('gold'), true);
      expect(g.balance, 1440);
    },
  );
  test('all bank state round trips; old saves preserve balances and debts', () {
    g.openLumaCard('classic');
    g.createLumaGoal('Bench', 3000);
    g.moveLumaGoal(g.luma.goals.single.id, 200);
    g.moveLumaBusiness(100);
    g.openLumaDeposit(100);
    g.borrowLuma(1000, 10);
    g.buyLumaStyle('aurora');
    g.updateLumaSettings(
      frozen: true,
      online: false,
      autoSave: true,
      limit: 500,
      pin: '1348',
    );
    final b = GameState();
    addTearDown(b.dispose);
    expect(b.importSave(g.exportSave()), true);
    expect(b.luma.toJson(), g.luma.toJson());
    expect(b.balance, g.balance);
    expect(b.loan, 1050);
    expect(b.luma.pinHash, hasLength(64));
    expect(b.luma.pinHash, isNot('1348'));
    final old = jsonDecode(g.exportSave()) as Map<String, dynamic>;
    old.remove('luma');
    old['balance'] = 857.5;
    old['loan'] = 230;
    old['invested'] = 600;
    expect(b.importSave(jsonEncode(old)), true);
    expect(b.balance, 857.5);
    expect(b.loan, 230);
    expect(b.invested, 600);
    expect(b.luma.opened, false);
  });
  test(
    'goals and business transfers conserve net worth and reject invalid money',
    () {
      g.openLumaCard('classic');
      g.createLumaGoal('Tools', 1000);
      final id = g.luma.goals.single.id;
      final worth = g.netWorth;
      for (final a in [-1.0, 0.0, double.nan, double.infinity, 1.001, 2000.0]) {
        expect(g.moveLumaGoal(id, a), false);
        expect(g.moveLumaBusiness(a), false);
      }
      expect(g.moveLumaGoal(id, 250), true);
      expect(g.moveLumaBusiness(300), true);
      expect(g.netWorth, worth);
      expect(g.moveLumaGoal(id, 251, withdraw: true), false);
      expect(g.moveLumaGoal(id, 250, withdraw: true), true);
      expect(g.moveLumaBusiness(301, withdraw: true), false);
      expect(g.moveLumaBusiness(300, withdraw: true), true);
      expect(g.balance, 1500);
      expect(g.netWorth, worth);
    },
  );
  test('transfers enforce freeze and daily limit, never overdraft', () {
    g.openLumaCard('classic');
    g.updateLumaSettings(limit: 100);
    expect(g.transferLuma('Alex', 90), true);
    expect(g.transferLuma('Alex', 11), false);
    expect(g.balance, 1410);
    g.updateLumaSettings(frozen: true);
    expect(g.transferLuma('Alex', 1), false);
    expect(g.buyLumaStyle('gold'), false);
    g.updateLumaSettings(frozen: false);
    day();
    expect(g.luma.spentToday, 0);
    expect(g.transferLuma('Alex', 100), true);
    expect(g.transferLuma('', 1), false);
    expect(g.transferLuma('Alex', double.nan), false);
    expect(g.transferLuma('Alex', .001), false);
  });
  test('deposit pays 5 percent once on day 31, never before', () {
    g.openLumaCard('classic');
    expect(g.openLumaDeposit(99), false);
    expect(g.openLumaDeposit(100), true);
    expect(g.balance, 1400);
    for (var i = 0; i < 29; i++) {
      day();
    }
    expect(g.balance, 1400);
    day();
    expect(g.balance, 1505);
    expect(g.luma.deposits, isEmpty);
    day();
    expect(g.balance, 1505);
  });
  test('fixed credit schedule settles exact cents and cannot be stacked', () {
    g.openLumaCard('classic');
    expect(g.borrowLuma(1000, 10), true);
    expect(g.loan, 1050);
    expect(g.balance, 2500);
    expect(g.borrowLuma(1000, 10), false);
    for (var i = 0; i < 10; i++) {
      day();
    }
    expect(g.loan, 0);
    expect(g.balance, 1450);
    expect(g.luma.creditDays, 0);
  });
  test(
    'insufficient credit payment stays due, no hidden compound interest',
    () {
      g.openLumaCard('classic');
      g.borrowLuma(1000, 10);
      g.balance = 0;
      day();
      expect(g.loan, 1050);
      expect(g.luma.creditDays, 10);
      expect(g.luma.missedPayments, 1);
      g.balance = 500;
      expect(g.repayLuma(500), true);
      expect(g.loan, 550);
      expect(g.balance, 0);
      expect(g.closeLumaCard(), false);
    },
  );
  test('business payments affect only business and recorded once', () {
    g.openLumaCard('classic');
    g.moveLumaBusiness(400);
    expect(g.transferLuma('Supplier', 401, fromBusiness: true), false);
    expect(g.transferLuma('Supplier', 150, fromBusiness: true), true);
    expect(g.luma.business, 250);
    expect(g.balance, 1100);
    expect(g.txns.first.amount, -150);
    expect(g.closeLumaCard(), false);
  });
  test(
    'market purchase is blocked by frozen or offline card; price and money stay atomic',
    () {
      g.openLumaCard('classic');
      final d =
          Deal(
              id: 'd',
              kind: 'buy',
              item: 'Phone',
              counterpart: 'Alex',
              market: 300,
              ask: 200,
              limit: 100,
            )
            ..status = 'agreed'
            ..price = 200;
      g.deals.add(d);
      g.updateLumaSettings(frozen: true);
      expect(g.confirmDeal(d), false);
      expect(g.balance, 1500);
      g.updateLumaSettings(frozen: false, online: false);
      expect(g.confirmDeal(d), false);
      g.updateLumaSettings(online: true);
      expect(g.confirmDeal(d), true);
      expect(g.balance, 1300);
      expect(g.luma.spentToday, 200);
      expect(g.confirmDeal(d), false);
      expect(g.balance, 1300);
    },
  );
  test('templates never spend money and PIN verification survives save', () {
    g.openLumaCard('classic');
    expect(g.saveLumaTemplate('Rent', 350), true);
    expect(g.balance, 1500);
    g.saveLumaTemplate('Rent', 300);
    expect(g.luma.templates.length, 1);
    expect(g.luma.templates.single.amount, 300);
    g.updateLumaSettings(pin: '8924');
    expect(g.verifyLumaPin('8924'), true);
    expect(g.verifyLumaPin('0000'), false);
    final b = GameState();
    addTearDown(b.dispose);
    expect(b.importSave(g.exportSave()), true);
    expect(b.verifyLumaPin('8924'), true);
    expect(b.luma.templates.single.recipient, 'Rent');
    g.deleteLumaTemplate('Rent');
    expect(g.luma.templates, isEmpty);
  });
  test(
    'early credit repayment shortens schedule and final payment closes it',
    () {
      g.openLumaCard('classic');
      g.borrowLuma(1000, 10);
      g.repayLuma(1000);
      expect(g.loan, 50);
      expect(g.luma.creditDays, 1);
      day();
      expect(g.loan, 0);
      expect(g.luma.creditDays, 0);
      expect(g.luma.creditDaily, 0);
    },
  );
  test('auto saving routes real sale income without creating net worth', () {
    g.openLumaCard('classic');
    g.createLumaGoal('Tools', 1000);
    g.updateLumaSettings(autoSave: true);
    final item = StockItem('s', 'Phone', 100, 200);
    g.stock.add(item);
    final d =
        Deal(
            id: 'sale',
            kind: 'sell',
            item: 'Phone',
            counterpart: 'Buyer',
            market: 200,
            ask: 200,
            limit: 100,
          )
          ..stockId = 's'
          ..status = 'agreed'
          ..price = 200;
    g.deals.add(d);
    expect(g.confirmDeal(d), true);
    expect(g.luma.saved, 20);
    expect(g.balance, 1680);
    expect(g.taxDue, 20);
  });
  test('card online controls also cover spare parts purchases', () {
    g.openLumaCard('classic');
    g.updateLumaSettings(online: false);
    expect(g.buyPart(products.first), false);
    expect(g.balance, 1500);
    g.updateLumaSettings(online: true);
    expect(g.buyPart(products.first), true);
    expect(g.luma.spentToday, products.first.price);
  });
}
