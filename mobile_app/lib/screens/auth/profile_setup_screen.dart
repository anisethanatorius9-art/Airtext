import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import 'auth_screen_frame.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({
    required this.controller,
    required this.photo,
    required this.isSwahili,
    required this.isSubmitting,
    required this.onPickPhoto,
    required this.onContinue,
    super.key,
  });

  final TextEditingController controller;
  final Uint8List? photo;
  final bool isSwahili;
  final bool isSubmitting;
  final VoidCallback onPickPhoto;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return AuthScreenFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            authCopy(isSwahili, 'Profile info', 'Taarifa za wasifu'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            authCopy(
              isSwahili,
              'Please provide your name and an optional profile photo.',
              'Weka jina lako na picha ya wasifu ikiwa ungependa.',
            ),
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.systemGrey5,
                  ),
                  child: photo == null
                      ? const Icon(
                          CupertinoIcons.person,
                          size: 36,
                          color: CupertinoColors.systemTeal,
                        )
                      : Image.memory(photo!, fit: BoxFit.cover),
                ),
                CupertinoButton(
                  onPressed: isSubmitting ? null : onPickPhoto,
                  child: Text(authCopy(isSwahili, 'Add photo', 'Ongeza picha')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AuthTextInput(
            controller: controller,
            label: authCopy(isSwahili, 'Your name', 'Jina lako'),
            placeholder: 'Aniseth Anatorius',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: authCopy(isSwahili, 'Next', 'Endelea'),
            isLoading: isSubmitting,
            icon: CupertinoIcons.arrow_right,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
