import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 28,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(4),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double size;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.account_balance_wallet,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (backgroundColor == null) {
      return image;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: image,
    );
  }
}
