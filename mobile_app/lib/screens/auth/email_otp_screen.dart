import 'package:flutter/cupertino.dart';

import 'auth_screen_frame.dart';

class EmailOtpScreen extends StatelessWidget {
  const EmailOtpScreen({
    required this.email,
    required this.controller,
    required this.isSwahili,
    required this.isSubmitting,
    required this.onVerify,
    required this.onResend,
    super.key,
  });

  final String email;
  final TextEditingController controller;
  final bool isSwahili;
  final bool isSubmitting;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return AuthScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            authCopy(
              isSwahili,
              'Verify your email',
              'Thibitisha barua pepe yako',
            ),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            authCopy(
              isSwahili,
              'Enter the 6-digit code sent to $email.',
              'Weka msimbo wa tarakimu 6 uliotumwa kwa $email.',
            ),
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AuthTextInput(
            controller: controller,
            label: authCopy(
              isSwahili,
              'Verification code',
              'Msimbo wa uthibitishaji',
            ),
            placeholder: '000000',
            keyboardType: TextInputType.number,
            maxLength: 6,
            centered: true,
            prefix: const Icon(CupertinoIcons.lock_shield, size: 19),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: isSubmitting ? null : onResend,
              child: Text(
                authCopy(
                  isSwahili,
                  "Didn't receive code? Resend",
                  'Hukupata code? Tuma tena',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AuthPrimaryButton(
            label: authCopy(isSwahili, 'Verify', 'Thibitisha'),
            isLoading: isSubmitting,
            icon: CupertinoIcons.checkmark_shield,
            onPressed: onVerify,
          ),
        ],
      ),
    );
  }
}
