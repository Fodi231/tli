import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../widgets.dart';

class PlaceholderApp extends StatelessWidget {
  final String titleKey;
  const PlaceholderApp({super.key, required this.titleKey});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: titleKey.tr,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 56, color: C.sub),
            const SizedBox(height: 12),
            Text('soon'.tr, style: const TextStyle(color: C.sub, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
