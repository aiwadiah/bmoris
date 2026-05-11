import 'package:flutter/material.dart';

class BMorisBackButton extends StatelessWidget {
  const BMorisBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed ?? () => Navigator.pop(context),
      icon: const Icon(Icons.arrow_back_rounded),
      tooltip: 'Back',
      color: const Color(0xFF00796B),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFE7F5F1),
        fixedSize: const Size(40, 40),
      ),
    );
  }
}
