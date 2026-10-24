part of '../game_state.dart';

extension LumaBank on GameState {
  bool verifyLumaPin(String pin) =>
      luma.pinHash.isEmpty ||
      sha256.convert(utf8.encode('Luma:$pin')).toString() == luma.pinHash;
  bool saveLumaTemplate(String name, double amount) {
    if (!luma.opened ||
        name.trim().isEmpty ||
        name.length > 80 ||
        !amount.isFinite ||
        amount <= 0 ||
        cents(amount) != amount ||
        luma.templates.length >= 20) {
      return false;
    }
    luma.templates.removeWhere((t) => t.recipient == name.trim());
    luma.templates.add(LumaPayment(name.trim(), amount));
    _changed();
    return true;
  }

  void deleteLumaTemplate(String name) {
    luma.templates.removeWhere((t) => t.recipient == name);
    _changed();
  }

  bool openLumaCard(String style) {
    if (luma.opened || !luma.ownedStyles.contains(style)) return false;
    luma.opened = true;
    luma.style = style;
    luma.frozen = false;
    _changed();
    return true;
  }

  bool closeLumaCard() {
    if (!luma.opened ||
        loan > 0 ||
        luma.saved > 0 ||
        luma.deposited > 0 ||
        luma.business > 0) {
      return false;
    }
    luma.opened = false;
    luma.frozen = false;
    _changed();
    return true;
  }

  void updateLumaSettings({
    bool? frozen,
    bool? online,
    bool? autoSave,
    double? limit,
    String? pin,
  }) {
    if (frozen != null) luma.frozen = frozen;
    if (online != null) luma.online = online;
    if (autoSave != null) luma.autoSave = autoSave;
    if (limit != null && limit.isFinite && limit >= 1 && limit <= 100000) {
      luma.dailyLimit = cents(limit);
    }
    if (pin != null && RegExp(r'^\d{4}$').hasMatch(pin)) {
      luma.pinHash = sha256.convert(utf8.encode('Luma:$pin')).toString();
    }
    _changed();
  }

  bool canLumaPay(double amount, {bool internet = false}) =>
      luma.opened &&
      !luma.frozen &&
      (!internet || luma.online) &&
      amount.isFinite &&
      amount > 0 &&
      cents(amount) == amount &&
      balance >= amount &&
      luma.spentToday + amount <= luma.dailyLimit;
  bool buyLumaStyle(String id) {
    final style = lumaStyles.where((s) => s.id == id).firstOrNull;
    if (style == null || !luma.opened) return false;
    if (!luma.ownedStyles.contains(id)) {
      if (!canLumaPay(style.price)) return false;
      _spend('Luma · ${style.name}', style.price);
      luma.spentToday += style.price;
      luma.ownedStyles.add(id);
    }
    luma.style = id;
    _changed();
    return true;
  }

  bool transferLuma(
    String recipient,
    double amount, {
    bool fromBusiness = false,
  }) {
    recipient = recipient.trim();
    if (recipient.isEmpty ||
        recipient.length > 80 ||
        !amount.isFinite ||
        amount <= 0 ||
        cents(amount) != amount) {
      return false;
    }
    if (fromBusiness) {
      if (!luma.businessOpened ||
          !luma.opened ||
          luma.frozen ||
          luma.business < amount ||
          luma.spentToday + amount > luma.dailyLimit) {
        return false;
      }
      luma.business = cents(luma.business - amount);
      txns.insert(0, Txn('Luma Business · $recipient', -amount));
      luma.businessTxns.insert(0, Txn(recipient, -amount));
    } else {
      if (!canLumaPay(amount)) return false;
      _spend('Luma · $recipient', amount);
    }
    luma.spentToday = cents(luma.spentToday + amount);
    luma.recent.removeWhere((p) => p.recipient == recipient);
    luma.recent.insert(0, LumaPayment(recipient, amount));
    if (luma.recent.length > 8) luma.recent.removeLast();
    _changed();
    return true;
  }

  bool moveLumaBusiness(double amount, {bool withdraw = false}) {
    if (!luma.opened ||
        !amount.isFinite ||
        amount <= 0 ||
        cents(amount) != amount ||
        (withdraw ? luma.business : balance) < amount) {
      return false;
    }
    luma.businessOpened = true;
    luma.businessTxns.insert(
      0,
      Txn(
        lumaText('Между счетами', 'Between accounts', 'Між рахунками'),
        withdraw ? -amount : amount,
      ),
    );
    luma.business = cents(luma.business + (withdraw ? -amount : amount));
    balance = cents(balance + (withdraw ? amount : -amount));
    txns.insert(
      0,
      Txn(
        lumaText(
          'Luma · Между счетами',
          'Luma · Between accounts',
          'Luma · Між рахунками',
        ),
        withdraw ? amount : -amount,
      ),
    );
    _changed();
    return true;
  }

  void openLumaBusiness() {
    if (!luma.opened) return;
    luma.businessOpened = true;
    _changed();
  }

  bool createLumaGoal(String name, double target) {
    if (!luma.opened ||
        name.trim().isEmpty ||
        name.trim().length > 60 ||
        !target.isFinite ||
        target < 1 ||
        target > 1000000 ||
        luma.goals.length >= 10) {
      return false;
    }
    luma.goals.add(SavingsGoal(nextId(), name.trim(), cents(target)));
    _changed();
    return true;
  }

  bool moveLumaGoal(String id, double amount, {bool withdraw = false}) {
    final goal = luma.goals.where((g) => g.id == id).firstOrNull;
    if (goal == null ||
        !amount.isFinite ||
        amount <= 0 ||
        cents(amount) != amount ||
        (withdraw ? goal.amount : balance) < amount) {
      return false;
    }
    goal.amount = cents(goal.amount + (withdraw ? -amount : amount));
    balance = cents(balance + (withdraw ? amount : -amount));
    txns.insert(0, Txn('Luma · ${goal.name}', withdraw ? amount : -amount));
    _changed();
    return true;
  }

  bool openLumaDeposit(double amount) {
    if (!luma.opened ||
        !amount.isFinite ||
        amount < 100 ||
        cents(amount) != amount ||
        balance < amount) {
      return false;
    }
    luma.deposits.add(LumaDeposit(amount, luma.day + 30));
    _spend(lumaText('Luma · Вклад', 'Luma · Deposit', 'Luma · Вклад'), amount);
    _changed();
    return true;
  }

  static double creditInterest(double amount, int days) =>
      cents(amount * days * 0.005);
  bool borrowLuma(double amount, int days) {
    if (!luma.opened ||
        luma.frozen ||
        loan > 0 ||
        !amount.isFinite ||
        amount < 100 ||
        amount > 10000 ||
        cents(amount) != amount ||
        ![5, 10, 20].contains(days)) {
      return false;
    }
    loan = cents(amount + creditInterest(amount, days));
    luma.creditDays = days;
    luma.creditDueDay = luma.day + 1;
    luma.creditDaily = cents(loan / days);
    balance = cents(balance + amount);
    txns.insert(
      0,
      Txn(lumaText('Luma · Кредит', 'Luma · Loan', 'Luma · Кредит'), amount),
    );
    _changed();
    return true;
  }

  bool repayLuma(double amount) {
    if (!amount.isFinite ||
        amount <= 0 ||
        cents(amount) != amount ||
        amount > loan ||
        amount > balance) {
      return false;
    }
    loan = cents(loan - amount);
    if (luma.creditDaily > 0) {
      luma.creditDays = min(luma.creditDays, (loan / luma.creditDaily).ceil());
    }
    _spend(
      lumaText(
        'Luma · Погашение кредита',
        'Luma · Loan repayment',
        'Luma · Погашення кредиту',
      ),
      amount,
    );
    if (loan == 0) {
      luma.creditDays = 0;
      luma.creditDaily = 0;
    }
    _changed();
    return true;
  }

  void _lumaAutoSave(double income) {
    if (!luma.opened || !luma.autoSave || luma.goals.isEmpty) return;
    final goal = luma.goals.where((g) => g.amount < g.target).firstOrNull;
    if (goal == null) return;
    final amount = cents(
      min(balance, min(goal.target - goal.amount, income * 0.1)),
    );
    if (amount <= 0) return;
    balance = cents(balance - amount);
    goal.amount = cents(goal.amount + amount);
    txns.insert(0, Txn('Luma · ${goal.name}', -amount));
  }

  @visibleForTesting
  void advanceLumaClockForTest() => _lumaTick();

  void _lumaTick() {
    luma.ticks++;
    if (luma.ticks < 30) return;
    luma.ticks = 0;
    luma.day++;
    luma.spentToday = 0;
    for (final deposit
        in luma.deposits.where((d) => d.dueDay <= luma.day).toList()) {
      final amount = cents(deposit.principal * 1.05);
      balance = cents(balance + amount);
      luma.deposits.remove(deposit);
      txns.insert(
        0,
        Txn(
          lumaText(
            'Luma · Вклад завершён',
            'Luma · Deposit matured',
            'Luma · Вклад завершено',
          ),
          amount,
        ),
      );
    }
    if (loan > 0 && luma.creditDays > 0 && luma.day >= luma.creditDueDay) {
      final due = luma.creditDays == 1 ? loan : min(loan, luma.creditDaily);
      if (balance >= due) {
        balance = cents(balance - due);
        loan = cents(loan - due);
        luma.creditDays--;
        if (loan == 0) {
          luma.creditDays = 0;
          luma.creditDaily = 0;
        }
        luma.creditDueDay = luma.day + 1;
        txns.insert(
          0,
          Txn(
            lumaText(
              'Luma · Платёж по кредиту',
              'Luma · Loan payment',
              'Luma · Платіж за кредитом',
            ),
            -due,
          ),
        );
      } else {
        luma.missedPayments++;
        _note(
          'bank',
          'bank',
          lumaText(
            'Недостаточно средств для платежа по кредиту.',
            'Insufficient funds for the loan payment.',
            'Недостатньо коштів для платежу за кредитом.',
          ),
        );
      }
    }
  }
}
