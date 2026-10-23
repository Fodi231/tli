import 'package:flutter/material.dart';
import '../market/marketplace_app.dart';

class MessagesApp extends StatelessWidget {
  final String? initialDealId;
  const MessagesApp({super.key, this.initialDealId});
  @override
  Widget build(BuildContext context) =>
      MarketplaceApp(initialTab: 3, initialDealId: initialDealId);
}
