import 'package:flutter/cupertino.dart';

String authCopy(bool isSwahili, String english, String swahili) =>
    isSwahili ? swahili : english;

class AuthScreenFrame extends StatelessWidget {
  const AuthScreenFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0A1718), Color(0xFF102423), Color(0xFF0B1718)]
              : const [Color(0xFFF2FAF9), Color(0xFFE3F5F2), Color(0xFFF7FBFA)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 22.0 : 34.0;
            final bottomPadding = MediaQuery.viewInsetsOf(context).bottom + 28;

            return Stack(
              children: [
                Positioned(
                  top: 52,
                  left: -32,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF087D78).withValues(alpha: 0.32)
                          : const Color(0xFFB9EDE7).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(90),
                    ),
                  ),
                ),
                Positioned(
                  right: -24,
                  bottom: 120,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2E7774).withValues(alpha: 0.18)
                          : const Color(0xFFD5F1EE).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(110),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A2723).withValues(alpha: 0.72)
                              : const Color(0xFFFFFDF9).withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF39544F).withValues(alpha: 0.7)
                                : const Color(0xFFD5EAE7)
                                      .withValues(alpha: 0.8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(0xFF06110E)
                                        .withValues(alpha: 0.42)
                                  : const Color(0xFFA9D8D1)
                                        .withValues(alpha: 0.28),
                              blurRadius: 26,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: isLoading ? null : onPressed,
        color: const Color(0xFF00A99D),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        borderRadius: BorderRadius.circular(14),
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class AuthTextInput extends StatelessWidget {
  const AuthTextInput({
    required this.controller,
    required this.label,
    this.placeholder,
    this.keyboardType,
    this.prefix,
    this.enabled = true,
    this.maxLength,
    this.centered = false,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final bool enabled;
  final int? maxLength;
  final bool centered;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          enabled: enabled,
          placeholder: placeholder,
          keyboardType: keyboardType,
          prefix: prefix == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: prefix,
                ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          maxLength: maxLength,
          obscureText: obscureText,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          textCapitalization: textCapitalization,
          autocorrect: false,
          onChanged: onChanged,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          style: TextStyle(
            fontSize: centered ? 24 : 17,
            letterSpacing: centered ? 6 : 0,
          ),
        ),
      ],
    );
  }
}

class AuthBrandMark extends StatelessWidget {
  const AuthBrandMark({this.size = 126, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/airtext_app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: 'AirText',
    );
  }
}
