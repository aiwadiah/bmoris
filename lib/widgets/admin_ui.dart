import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUi {
  static const Color teal = Color(0xFF0B8A7B);
  static const Color tealDark = Color(0xFF08695E);
  static const Color mint = Color(0xFFE8F6F2);
  static const Color surface = Color(0xFFF6F7F9);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF1F2A2C);
  static const Color muted = Color(0xFF7B8A8D);
  static const Color border = Color(0xFFE4E9EB);
  static const Color danger = Color(0xFFE06363);
  static const double radius = 18;

  static TextStyle headline([Color color = text]) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle title([Color color = text]) => GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: color,
  );

  static TextStyle body([Color color = text]) => GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle caption([Color color = muted]) => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: color,
  );
}

class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.child,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  final Widget child;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AdminUi.surface,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(child: child),
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminUi.headline(AdminUi.tealDark)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AdminUi.caption()),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: padding,
            child: child,
          ),
        ),
      ],
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AdminUi.card,
        borderRadius: BorderRadius.circular(AdminUi.radius),
        border: Border.all(color: AdminUi.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AdminUi.teal,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AdminUi.text,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AdminUi.muted,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminActionButton extends StatelessWidget {
  const AdminActionButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
  }) : outlined = false,
       danger = false;

  const AdminActionButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
  }) : outlined = true,
       danger = false;

  const AdminActionButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
  }) : outlined = true,
       danger = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool danger;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final foreground =
        danger ? AdminUi.danger : (outlined ? AdminUi.teal : Colors.white);
    final background =
        outlined ? Colors.white : (danger ? Colors.white : AdminUi.teal);
    final borderColor = danger ? AdminUi.danger : AdminUi.teal;

    final child = SizedBox(
      height: 46,
      child:
          outlined
              ? OutlinedButton.icon(
                onPressed: onPressed,
                icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
                label: Text(label, style: AdminUi.body(foreground)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  backgroundColor: background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
              : ElevatedButton.icon(
                onPressed: onPressed,
                icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
                label: Text(label, style: AdminUi.body(foreground)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: background,
                  foregroundColor: foreground,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
    );

    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class AdminPill extends StatelessWidget {
  const AdminPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.foreground,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? (selected ? Colors.white : AdminUi.muted);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AdminUi.teal : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AdminUi.teal : AdminUi.border,
          ),
        ),
        child: Text(label, style: AdminUi.caption(fg)),
      ),
    );
  }
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AdminUi.body(AdminUi.muted),
        prefixIcon: const Icon(Icons.search_rounded, color: AdminUi.muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AdminUi.border),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AdminUi.teal),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AdminUi.title()),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AdminUi.teal),
          const SizedBox(height: 12),
          Text(title, style: AdminUi.title(), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AdminUi.body(AdminUi.muted),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

InputDecoration adminInputDecoration({
  required String label,
  String? hint,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    labelStyle: AdminUi.body(AdminUi.muted),
    hintStyle: AdminUi.body(AdminUi.muted),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminUi.border),
      borderRadius: BorderRadius.circular(14),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminUi.teal),
      borderRadius: BorderRadius.circular(14),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminUi.danger),
      borderRadius: BorderRadius.circular(14),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AdminUi.danger),
      borderRadius: BorderRadius.circular(14),
    ),
  );
}
