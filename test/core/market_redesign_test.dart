import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:techlife/core/game_state.dart';
import 'package:techlife/core/models.dart';
import 'package:techlife/core/market/market_models.dart';

StockItem owned() => StockItem(
  'owned13',
  'iPhone 13',
  195,
  420,
  deviceId: 'iphone13',
  repaired: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'draft and listing content survive saves without spending or selling',
    () {
      final gs = GameState(), restored = GameState(), listed = GameState();
      addTearDown(gs.dispose);
      addTearDown(restored.dispose);
      addTearDown(listed.dispose);
      final item = owned();
      gs.stock.add(item);
      expect(
        gs.saveMarketDraft(
          item,
          title: 'My restored iPhone',
          description: 'Display replaced and tested.',
          price: '410',
          photos: ['assets/market/iphone13.jpg'],
        ),
        isTrue,
      );
      expect(gs.balance, 1500);
      expect(gs.deals, isEmpty);
      expect(gs.playerListings, isEmpty);
      expect(restored.importSave(gs.exportSave()), isTrue);
      expect(restored.marketDrafts[item.id]!.title, 'My restored iPhone');
      expect(restored.marketDrafts[item.id]!.photos, [
        'assets/market/iphone13.jpg',
      ]);
      final stock = restored.stock.single;
      expect(restored.publishListing(stock, double.nan, 'test'), isNull);
      expect(restored.marketDrafts, contains(item.id));
      final l =
          restored.publishListing(
            stock,
            410,
            'Display replaced and tested.',
            title: 'My restored iPhone',
            photos: ['assets/market/iphone13.jpg'],
          )!;
      expect(l.condition, 'repaired');
      expect(l.deviceId, 'iphone13');
      expect(restored.marketDrafts, isEmpty);
      expect(restored.stock, hasLength(1));
      expect(restored.balance, 1500);
      expect(listed.importSave(restored.exportSave()), isTrue);
      final copy = listed.playerListings.single;
      expect(copy.title, l.title);
      expect(copy.description, l.description);
      expect(copy.photos, l.photos);
      expect(copy.deviceId, l.deviceId);
      expect(copy.condition, 'repaired');
    },
  );
  test('a draft cannot claim a device outside the inventory', () {
    final gs = GameState();
    addTearDown(gs.dispose);
    expect(
      gs.saveMarketDraft(
        owned(),
        title: 'x',
        description: 'x',
        price: '100',
        photos: [],
      ),
      isFalse,
    );
    expect(gs.marketDrafts, isEmpty);
    expect(gs.balance, 1500);
  });
  test('unread count includes messages sharing the last read timestamp', () {
    final gs = GameState();
    addTearDown(gs.dispose);
    final d = gs.openMarketDeal('m01')!;
    expect(d.unreadMessages, 1);
    final sameTime = d.messages.first.at;
    gs.markDealRead(d);
    expect(d.unreadMessages, 0);
    d.messages.add(ChatMsg(false, 'Same millisecond reply', at: sameTime));
    d.messages.add(ChatMsg(true, 'My own reply', at: sameTime));
    expect(d.unreadMessages, 1);
    expect(gs.unreadMarketMessages, 1);
    expect(Deal.fromJson(d.toJson()).unreadMessages, 1);
    gs.markDealRead(d);
    expect(d.unreadMessages, 0);
  });
  test('saved price alerts compare real snapshots and do not repeat', () {
    final gs = GameState(), restored = GameState();
    addTearDown(gs.dispose);
    addTearDown(restored.dispose);
    gs.toggleFavorite('m01');
    expect(gs.favoriteReferencePrices['m01'], 195);
    gs.favoriteReferencePrices['m01'] =
        220; // Snapshot from a previous catalog revision.
    gs.checkFavoritePriceDrops();
    expect(gs.favoritePriceDropped(listingFor('m01')!), isTrue);
    expect(
      gs.notifications.where((n) => n.titleKey == 'market_price_drop'),
      hasLength(1),
    );
    gs.checkFavoritePriceDrops();
    expect(
      gs.notifications.where((n) => n.titleKey == 'market_price_drop'),
      hasLength(1),
    );
    gs.setFavoritePriceAlerts(false);
    expect(restored.importSave(gs.exportSave()), isTrue);
    expect(restored.favoritePriceAlerts, isFalse);
    expect(restored.favoriteReferencePrices['m01'], 220);
    gs.toggleFavorite('m01');
    expect(gs.favoriteReferencePrices, isEmpty);
    final legacy = jsonDecode(restored.exportSave()) as Map<String, dynamic>;
    legacy.remove('favoritePrices');
    expect(restored.importSave(jsonEncode(legacy)), isTrue);
    expect(restored.favoriteReferencePrices['m01'], 195);
  });
  test('listing photos do not accept arbitrary URLs from imported saves', () {
    final l = PlayerListing.fromJson({
      'id': 'l',
      'stock': 's',
      'title': 'Phone',
      'description': '',
      'price': 100,
      'photos': [
        'https://example.com/tracker.png',
        'javascript:alert(1)',
        'assets/market/iphone13.jpg',
      ],
    });
    expect(l.photos, ['assets/market/iphone13.jpg']);
    expect(
      PlayerListing.fromJson({
        'id': 'old',
        'stock': 's',
        'title': 'Phone',
        'description': '',
        'price': 100,
      }).photos,
      isEmpty,
    );
  });
}
