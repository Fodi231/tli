import 'package:flutter/material.dart';
import '../../core/i18n.dart';
import '../../core/market/market_strings.dart';
import '../../core/theme.dart';
import '../widgets.dart';

class PlaceholderApp extends StatelessWidget {
  final String titleKey;
  const PlaceholderApp({super.key, required this.titleKey});
  @override
  Widget build(BuildContext context) {
    final p = IosColors.of(context);
    return AppPage(
      title: titleKey.tr,
      child: SingleChildScrollView(
        child: Panel(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: p.blue.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  switch (titleKey) {
                    'mail' => Icons.mail_outline_rounded,
                    'calendar' => Icons.calendar_month_rounded,
                    'staff' => Icons.groups_outlined,
                    _ => Icons.apps_rounded,
                  },
                  size: 37,
                  color: p.blue,
                ),
              ),
              const SizedBox(height: 23),
              Text(
                mt(
                  'Скоро в TechLife',
                  'Coming to TechLife',
                  'Незабаром у TechLife',
                ),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                mt(
                  'Это приложение появится в одном из обновлений. Пока можно заняться техникой и заказами.',
                  'This app is planned for an update. For now, explore devices and repair orders.',
                  'Цей застосунок з’явиться в одному з оновлень. Поки можна зайнятися технікою й замовленнями.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: p.secondary, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}
