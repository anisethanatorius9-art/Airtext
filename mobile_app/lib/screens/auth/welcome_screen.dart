import 'package:flutter/cupertino.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

import 'auth_screen_frame.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.language,
    required this.onChooseLanguage,
    required this.onContinue,
    this.continueLabel,
    super.key,
  });

  final String language;
  final VoidCallback onChooseLanguage;
  final VoidCallback onContinue;
  final String? continueLabel;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? const Color(0xFFF1F5F3)
        : const Color(0xFF18231E);
    final secondaryTextColor = isDark
        ? const Color(0xFFB8C1BC)
        : const Color(0xFF5F6D67);

    return AuthScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Center(child: AuthBrandMark()),
          const SizedBox(height: 34),
          Text(
            strings.welcomeTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 31,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.welcomeSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 17,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2C29) : const Color(0xFFEAF4F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF355449)
                    : const Color(0xFFCFE9DD),
              ),
            ),
            child: Text(
              strings.welcomePromise,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            strings.preferredLanguage,
            style: TextStyle(
              color: primaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: isDark ? const Color(0xFF202A25) : const Color(0xFFE8EEEA),
            borderRadius: BorderRadius.circular(14),
            onPressed: onChooseLanguage,
            child: Row(
              children: [
                const Icon(CupertinoIcons.globe, color: Color(0xFF00A99D)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    language,
                    style: TextStyle(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  color: Color(0xFF00A99D),
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          AuthPrimaryButton(
            label: continueLabel ?? strings.agreeAndContinue,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
