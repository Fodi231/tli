import '../i18n.dart';
import '../models.dart';

String lumaText(String ru, String en, String uk) =>
    I18n.lang == 'en'
        ? en
        : I18n.lang == 'uk'
        ? uk
        : ru;
double cents(double v) => (v * 100).round() / 100;

class CardStyle {
  final String id, name;
  final double price;
  const CardStyle(this.id, this.name, this.price);
}

const lumaStyles = [
  CardStyle('classic', 'Classic', 0),
  CardStyle('pearl', 'Pearl', 0),
  CardStyle('midnight', 'Midnight', 0),
  CardStyle('aurora', 'Aurora', 25),
  CardStyle('chrome', 'Liquid Chrome', 40),
  CardStyle('gold', 'Gold', 60),
];

class SavingsGoal {
  final String id;
  String name;
  double target, amount;
  SavingsGoal(this.id, this.name, this.target, [this.amount = 0]);
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'target': target,
    'amount': amount,
  };
  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
    j['id'],
    j['name'],
    (j['target'] as num).toDouble(),
    (j['amount'] as num).toDouble(),
  );
}

class LumaDeposit {
  final double principal;
  final int dueDay;
  LumaDeposit(this.principal, this.dueDay);
  Map<String, dynamic> toJson() => {'principal': principal, 'due': dueDay};
}

class LumaPayment {
  final String recipient;
  final double amount;
  LumaPayment(this.recipient, this.amount);
  Map<String, dynamic> toJson() => {'recipient': recipient, 'amount': amount};
}

class LumaState {
  bool opened = false,
      frozen = false,
      online = true,
      autoSave = false,
      businessOpened = false;
  String style = 'classic', pinHash = '';
  Set<String> ownedStyles = {'classic', 'pearl', 'midnight'};
  double dailyLimit = 2000, spentToday = 0, business = 0;
  int ticks = 0, day = 1, creditDays = 0, creditDueDay = 0, missedPayments = 0;
  double creditDaily = 0;
  List<SavingsGoal> goals = [];
  List<LumaDeposit> deposits = [];
  List<LumaPayment> recent = [];
  List<LumaPayment> templates = [];
  List<Txn> businessTxns = [];
  // One game day is ten minutes of active play (30 economy ticks).
  double get saved => goals.fold(0.0, (s, g) => s + g.amount);
  double get deposited => deposits.fold(0.0, (s, d) => s + d.principal);
  Map<String, dynamic> toJson() => {
    'opened': opened,
    'frozen': frozen,
    'online': online,
    'auto': autoSave,
    'businessOpened': businessOpened,
    'style': style,
    'pin': pinHash,
    'owned': ownedStyles.toList(),
    'limit': dailyLimit,
    'spent': spentToday,
    'business': business,
    'ticks': ticks,
    'day': day,
    'creditDays': creditDays,
    'creditDueDay': creditDueDay,
    'creditDaily': creditDaily,
    'missed': missedPayments,
    'goals': goals.map((g) => g.toJson()).toList(),
    'deposits': deposits.map((d) => d.toJson()).toList(),
    'recent': recent.map((r) => r.toJson()).toList(),
    'templates': templates.map((r) => r.toJson()).toList(),
    'businessTxns': businessTxns.map((t) => t.toJson()).toList(),
  };
  factory LumaState.fromJson(Map<String, dynamic> j) {
    final b = LumaState();
    b.opened = j['opened'] == true;
    b.frozen = j['frozen'] == true;
    b.online = j['online'] != false;
    b.autoSave = j['auto'] == true;
    b.businessOpened = j['businessOpened'] == true;
    b.style = j['style'] as String? ?? 'classic';
    b.pinHash = j['pin'] as String? ?? '';
    b.ownedStyles.addAll(List<String>.from(j['owned'] ?? []));
    b.dailyLimit = (j['limit'] as num? ?? 2000).toDouble();
    b.spentToday = (j['spent'] as num? ?? 0).toDouble();
    b.business = (j['business'] as num? ?? 0).toDouble();
    b.ticks = j['ticks'] as int? ?? 0;
    b.day = j['day'] as int? ?? 1;
    b.creditDays = j['creditDays'] as int? ?? 0;
    b.creditDueDay = j['creditDueDay'] as int? ?? 0;
    b.creditDaily = (j['creditDaily'] as num? ?? 0).toDouble();
    b.missedPayments = j['missed'] as int? ?? 0;
    b.goals =
        (j['goals'] as List? ?? [])
            .map((g) => SavingsGoal.fromJson(Map<String, dynamic>.from(g)))
            .toList();
    b.deposits =
        (j['deposits'] as List? ?? [])
            .map(
              (d) => LumaDeposit(
                (d['principal'] as num).toDouble(),
                d['due'] as int,
              ),
            )
            .toList();
    b.recent =
        (j['recent'] as List? ?? [])
            .map(
              (r) =>
                  LumaPayment(r['recipient'], (r['amount'] as num).toDouble()),
            )
            .toList();
    b.templates =
        (j['templates'] as List? ?? [])
            .map(
              (r) =>
                  LumaPayment(r['recipient'], (r['amount'] as num).toDouble()),
            )
            .toList();
    b.businessTxns =
        (j['businessTxns'] as List? ?? [])
            .map((t) => Txn.fromJson(Map<String, dynamic>.from(t)))
            .toList();
    return b;
  }
  LumaState();
}
