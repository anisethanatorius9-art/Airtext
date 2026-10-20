// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTitle => 'Welcome to AirText';

  @override
  String get welcomeSubtitle => 'Secure messaging made beautifully human.';

  @override
  String get welcomePromise => 'Private, elegant, and ready on every device.';

  @override
  String get preferredLanguage => 'Preferred language';

  @override
  String get agreeAndContinue => 'Agree and continue';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get searchLanguage => 'Search language';
}
