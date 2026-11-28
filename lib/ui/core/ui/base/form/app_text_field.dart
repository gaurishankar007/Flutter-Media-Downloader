import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_spacing.dart';
import 'package:media_tool/ui/core/themes/theme.dart';

/// A single-line text field on a raised, rounded surface (passwords, page ranges).
class const AppTextField({
  super.key,
  required final String hint,
  required final ValueChanged<String> onChanged,
  final String? initialValue,
  final IconData? icon,
  final bool obscure = false,
  final TextInputType? keyboardType,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 48,
      padding: const .symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: AppRadius.mdAll,
        border: .all(color: colors.outline),
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          if (icon != null) Icon(icon, size: 20, color: colors.textMuted),
          Expanded(
            child: TextFormField(
              initialValue: initialValue,
              onChanged: onChanged,
              obscureText: obscure,
              autocorrect: !obscure,
              enableSuggestions: !obscure,
              keyboardType: keyboardType,
              style: context.text.body,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: context.text.body.copyWith(color: colors.textMuted),
                border: .none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
