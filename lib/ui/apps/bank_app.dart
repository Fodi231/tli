import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';

class BankApp extends StatelessWidget {
  const BankApp({super.key});

  Widget _row(String label, String value, {Widget? action}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (action != null) ...[const SizedBox(width: 8), action],
          ],
        ),
      );

  Widget _btn(String t, VoidCallback f) => FilledButton(
        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
        onPressed: f,
        child: Text(t, style: const TextStyle(fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    final gs = context.watch<GameState>();
    final g = context.read<GameState>();
    return AppPage(
      title: 'bank'.tr,
      child: ListView(
        children: [
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('balance'.tr, style: const TextStyle(color: C.sub)),
                Text(money(gs.balance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Panel(
            child: Column(children: [
              _row('credits'.tr, money(gs.loan), action: _btn('take_loan'.tr, g.takeLoan)),
              if (gs.loan > 0) Align(alignment: Alignment.centerRight, child: _btn('repay'.tr, g.repayLoan)),
              const Divider(color: Colors.white12),
              _row('invest'.tr, money(gs.invested), action: _btn('invest_btn'.tr, g.investMoney)),
              if (gs.invested > 0) Align(alignment: Alignment.centerRight, child: _btn('withdraw'.tr, g.withdrawInvest)),
              const Divider(color: Colors.white12),
              _row('taxes'.tr, money(gs.taxDue), action: _btn('pay'.tr, g.payTaxes)),
              const Divider(color: Colors.white12),
              _row(
                'insurance'.tr,
                gs.insured ? 'insured'.tr : '-',
                action: gs.insured
                    ? null
                    : _btn('buy_ins'.tr, () {
                        if (!g.buyInsurance()) toast(context, 'no_money'.tr);
                      }),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Text('history'.tr, style: const TextStyle(color: C.sub, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          for (final t in gs.txns.take(25))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(t.title, style: const TextStyle(fontSize: 13))),
                  Text(
                    (t.amount >= 0 ? '+' : '') + money(t.amount),
                    style: TextStyle(color: t.amount >= 0 ? C.green : C.red, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
