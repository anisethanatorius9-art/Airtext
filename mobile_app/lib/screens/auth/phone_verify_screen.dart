import 'package:flutter/cupertino.dart';

import 'auth_screen_frame.dart';

class PhoneVerifyScreen extends StatelessWidget {
  const PhoneVerifyScreen({
    required this.phoneController,
    required this.codeController,
    required this.countryCode,
    required this.countries,
    required this.codeRequested,
    required this.isLoginChallenge,
    required this.phoneHint,
    required this.isSwahili,
    required this.isSubmitting,
    required this.onCountryChanged,
    required this.onPhoneChanged,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController phoneController;
  final TextEditingController codeController;
  final String countryCode;
  final Map<String, String> countries;
  final bool codeRequested;
  final bool isLoginChallenge;
  final String? phoneHint;
  final bool isSwahili;
  final bool isSubmitting;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AuthScreenFrame(
      child: isLoginChallenge
          ? _buildLoginChallenge()
          : _buildPhoneBinding(context),
    );
  }

  Widget _buildPhoneBinding(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          authCopy(isSwahili, 'Verify your phone', 'Thibitisha namba ya simu'),
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          authCopy(
            isSwahili,
            'Phone verification is required to secure your account. We will send a code by SMS.',
            'Uthibitishaji wa simu unahitajika kulinda akaunti yako. Tutatuma msimbo kwa SMS.',
          ),
          style: const TextStyle(
            color: CupertinoColors.secondaryLabel,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          authCopy(isSwahili, 'Country', 'Nchi'),
          style: const TextStyle(
            color: CupertinoColors.secondaryLabel,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(14),
          onPressed: isSubmitting ? null : () => _chooseCountry(context),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$_countryName ($countryCode)',
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                    fontSize: 17,
                  ),
                ),
              ),
              const Icon(CupertinoIcons.chevron_down, size: 17),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AuthTextInput(
          controller: phoneController,
          label: authCopy(isSwahili, 'Phone number', 'Namba ya simu'),
          placeholder: '712 345 678',
          keyboardType: TextInputType.phone,
          prefix: Text(countryCode),
          onChanged: onPhoneChanged,
        ),
        if (codeRequested) ...[
          const SizedBox(height: 18),
          AuthTextInput(
            controller: codeController,
            label: authCopy(
              isSwahili,
              'SMS verification code',
              'Msimbo wa SMS',
            ),
            placeholder: '000000',
            keyboardType: TextInputType.number,
            maxLength: 6,
            centered: true,
          ),
        ],
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: codeRequested
              ? authCopy(isSwahili, 'Verify & secure', 'Thibitisha na linda')
              : authCopy(isSwahili, 'Send SMS code', 'Tuma msimbo wa SMS'),
          isLoading: isSubmitting,
          icon: CupertinoIcons.lock_shield,
          onPressed: onSubmit,
        ),
      ],
    );
  }

  Widget _buildLoginChallenge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          authCopy(isSwahili, 'Verify your phone', 'Thibitisha simu yako'),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          authCopy(
            isSwahili,
            'Enter the 6-digit code sent to ${phoneHint ?? 'your verified phone'}.',
            'Weka msimbo wa tarakimu 6 uliotumwa kwa ${phoneHint ?? 'simu yako iliyothibitishwa'}.',
          ),
          style: const TextStyle(
            color: CupertinoColors.secondaryLabel,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        AuthTextInput(
          controller: codeController,
          label: authCopy(isSwahili, 'SMS verification code', 'Msimbo wa SMS'),
          placeholder: '000000',
          keyboardType: TextInputType.number,
          maxLength: 6,
          centered: true,
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          label: authCopy(
            isSwahili,
            'Verify and sign in',
            'Thibitisha na uingie',
          ),
          isLoading: isSubmitting,
          icon: CupertinoIcons.checkmark_shield,
          onPressed: onSubmit,
        ),
      ],
    );
  }

  String get _countryName => countries.entries
      .firstWhere(
        (entry) => entry.value == countryCode,
        orElse: () => countries.entries.first,
      )
      .key;

  Future<void> _chooseCountry(BuildContext context) async {
    final selected = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(authCopy(isSwahili, 'Select country', 'Chagua nchi')),
        actions: [
          for (final country in countries.entries)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, country.value),
              child: Text('${country.key} (${country.value})'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(authCopy(isSwahili, 'Cancel', 'Ghairi')),
        ),
      ),
    );
    if (selected != null) onCountryChanged(selected);
  }
}
