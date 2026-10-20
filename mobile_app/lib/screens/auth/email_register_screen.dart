import 'package:flutter/cupertino.dart';

import 'auth_screen_frame.dart';

class EmailRegisterScreen extends StatelessWidget {
  const EmailRegisterScreen({
    required this.controller,
    required this.isSwahili,
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController controller;
  final bool isSwahili;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AuthScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            authCopy(isSwahili, 'Enter your email', 'Weka barua pepe yako'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            authCopy(
              isSwahili,
              'We will send a secure verification code to your email address.',
              'Tutakutumia msimbo salama wa uthibitishaji kwenye barua pepe yako.',
            ),
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          AuthTextInput(
            controller: controller,
            label: authCopy(isSwahili, 'Email address', 'Barua pepe'),
            placeholder: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            prefix: const Icon(CupertinoIcons.mail, size: 19),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: authCopy(isSwahili, 'Next / Send OTP', 'Endelea / Tuma OTP'),
            isLoading: isSubmitting,
            icon: CupertinoIcons.paperplane,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
