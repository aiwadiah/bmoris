import 'package:flutter/material.dart';

class BMorisBackButton extends StatelessWidget {
  const BMorisBackButton({super.key, this.onPressed})
    : color = const Color(0xFF00796B),
      _variant = _BMorisBackButtonVariant.filled;

  const BMorisBackButton.plain({
    super.key,
    this.onPressed,
    this.color = const Color(0xFF00796B),
  }) : _variant = _BMorisBackButtonVariant.plain;

  static const double size = 36;
  static const double iconSize = 18;
  static const double leadingWidth = 44;
  static const double plainSize = 32;
  static const double plainLeadingWidth = 36;

  final VoidCallback? onPressed;
  final Color color;
  final _BMorisBackButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final onTap = onPressed ?? () => Navigator.pop(context);

    if (_variant == _BMorisBackButtonVariant.plain) {
      return IconButton(
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back_rounded, size: iconSize),
        tooltip: 'Back',
        color: color,
        style: IconButton.styleFrom(
          fixedSize: const Size.square(plainSize),
          minimumSize: const Size.square(plainSize),
          maximumSize: const Size.square(plainSize),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    return IconButton.filledTonal(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_back_rounded, size: iconSize),
      tooltip: 'Back',
      color: const Color(0xFF00796B),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFE7F5F1),
        fixedSize: const Size.square(size),
        minimumSize: const Size.square(size),
        maximumSize: const Size.square(size),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

enum _BMorisBackButtonVariant { filled, plain }
