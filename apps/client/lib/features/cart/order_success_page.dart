import 'dart:async';

import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import 'widgets/success_check.dart';

/// Full-screen order confirmation with a drawn checkmark, then auto-routes to
/// home after ~1.8s (SPEC §12). Order tracking lands in the orders feature.
class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    // Short, readable order ref (full uuid is long).
    final shortId = widget.orderId.split('-').first;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SuccessCheck(),
              const SizedBox(height: AppTheme.space * 3),
              Text(t.orderPlacedTitle, style: text.headlineMedium),
              const SizedBox(height: AppTheme.space),
              Text(
                t.orderPlacedSubtitle,
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space),
              Text(t.orderNumber(shortId), style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
