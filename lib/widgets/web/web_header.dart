import 'package:flutter/material.dart';

/// Header pour le dashboard web
class WebHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const WebHeader({
    super.key,
    required this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    // Header vide - titre et profil supprimés
    return const SizedBox.shrink();
  }
}
