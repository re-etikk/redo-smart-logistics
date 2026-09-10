import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('or'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'REDO Customer'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @bookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @sendParcel.
  ///
  /// In en, this message translates to:
  /// **'Send Parcel'**
  String get sendParcel;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @recentBookings.
  ///
  /// In en, this message translates to:
  /// **'Recent Bookings'**
  String get recentBookings;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @noActiveBookings.
  ///
  /// In en, this message translates to:
  /// **'No active bookings yet'**
  String get noActiveBookings;

  /// No description provided for @noActiveBookingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter pickup and drop locations above to find return trucks.'**
  String get noActiveBookingsDesc;

  /// No description provided for @exactAddressesGstin.
  ///
  /// In en, this message translates to:
  /// **'Exact Addresses & GSTIN'**
  String get exactAddressesGstin;

  /// No description provided for @exactAddressesGstinDesc.
  ///
  /// In en, this message translates to:
  /// **'Add pickup/drop landmarks & GST (optional)'**
  String get exactAddressesGstinDesc;

  /// No description provided for @findTrucks.
  ///
  /// In en, this message translates to:
  /// **'Find Trucks'**
  String get findTrucks;

  /// No description provided for @registerLoad.
  ///
  /// In en, this message translates to:
  /// **'Register Load'**
  String get registerLoad;

  /// No description provided for @bookShipment.
  ///
  /// In en, this message translates to:
  /// **'Book Shipment'**
  String get bookShipment;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// No description provided for @dropLocation.
  ///
  /// In en, this message translates to:
  /// **'Drop Location'**
  String get dropLocation;

  /// No description provided for @instantDispatch.
  ///
  /// In en, this message translates to:
  /// **'⚡ Ship Now (Instant)'**
  String get instantDispatch;

  /// No description provided for @scheduleLater.
  ///
  /// In en, this message translates to:
  /// **'📅 Ship Later'**
  String get scheduleLater;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme Settings'**
  String get themeSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistant;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @tapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get tapToSpeak;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop Listening'**
  String get stopListening;

  /// No description provided for @aiChat.
  ///
  /// In en, this message translates to:
  /// **'AI Chat Assistant'**
  String get aiChat;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask about freight, rates, trucks, or routes...'**
  String get askAnything;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfile;

  /// No description provided for @typeLocation.
  ///
  /// In en, this message translates to:
  /// **'Type a location...'**
  String get typeLocation;

  /// No description provided for @myShipments.
  ///
  /// In en, this message translates to:
  /// **'My Shipments'**
  String get myShipments;

  /// No description provided for @trackShipment.
  ///
  /// In en, this message translates to:
  /// **'Track Shipment'**
  String get trackShipment;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// No description provided for @customerProfile.
  ///
  /// In en, this message translates to:
  /// **'Customer Profile'**
  String get customerProfile;

  /// No description provided for @customerProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your registered enterprise account and tax compliance.'**
  String get customerProfileSubtitle;

  /// No description provided for @enterpriseShipper.
  ///
  /// In en, this message translates to:
  /// **'ENTERPRISE SHIPPER'**
  String get enterpriseShipper;

  /// No description provided for @registerYourBusiness.
  ///
  /// In en, this message translates to:
  /// **'Register Your Business'**
  String get registerYourBusiness;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @verificationLegalKyc.
  ///
  /// In en, this message translates to:
  /// **'Verification & Legal KYC'**
  String get verificationLegalKyc;

  /// No description provided for @fullyVerified.
  ///
  /// In en, this message translates to:
  /// **'Fully Verified'**
  String get fullyVerified;

  /// No description provided for @mobileVerification.
  ///
  /// In en, this message translates to:
  /// **'Mobile Verification'**
  String get mobileVerification;

  /// No description provided for @emailAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Email Authentication'**
  String get emailAuthentication;

  /// No description provided for @companyRegistration.
  ///
  /// In en, this message translates to:
  /// **'Company Registration'**
  String get companyRegistration;

  /// No description provided for @gstinTaxCompliance.
  ///
  /// In en, this message translates to:
  /// **'GSTIN / Tax Compliance'**
  String get gstinTaxCompliance;

  /// No description provided for @registeredAddress.
  ///
  /// In en, this message translates to:
  /// **'Registered Warehouse Address'**
  String get registeredAddress;

  /// No description provided for @businessTaxInfo.
  ///
  /// In en, this message translates to:
  /// **'Business & Tax Information'**
  String get businessTaxInfo;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get contactPerson;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @gstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get gstin;

  /// No description provided for @panNumber.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get panNumber;

  /// No description provided for @invoicesBilling.
  ///
  /// In en, this message translates to:
  /// **'Invoices & Billing'**
  String get invoicesBilling;

  /// No description provided for @invoicesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View GST tax invoices and payment receipts'**
  String get invoicesSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shipment alerts, status pings and announcements'**
  String get notificationsSubtitle;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'24/7 dedicated freight and booking assistance'**
  String get helpSupportSubtitle;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from this device'**
  String get logOutSubtitle;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Business Profile & KYC'**
  String get editProfileTitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your company and tax details for verified freight shipping.'**
  String get editProfileSubtitle;

  /// No description provided for @saveProfileKyc.
  ///
  /// In en, this message translates to:
  /// **'Save Profile & KYC'**
  String get saveProfileKyc;

  /// No description provided for @selectVehicle.
  ///
  /// In en, this message translates to:
  /// **'Select Commercial Vehicle'**
  String get selectVehicle;

  /// No description provided for @vehicleRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Recommended for your cargo load'**
  String get vehicleRecommendation;

  /// No description provided for @payloadTonnage.
  ///
  /// In en, this message translates to:
  /// **'Payload Tonnage'**
  String get payloadTonnage;

  /// No description provided for @profileCompletionVerifiedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your business profile and tax credentials are fully verified.'**
  String get profileCompletionVerifiedDesc;

  /// No description provided for @profileCompletionPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete remaining business details to unlock instant matching.'**
  String get profileCompletionPendingDesc;

  /// No description provided for @completeProfileNow.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile Now →'**
  String get completeProfileNow;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @pendingRegistration.
  ///
  /// In en, this message translates to:
  /// **'Pending registration'**
  String get pendingRegistration;

  /// No description provided for @logOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from this device?'**
  String get logOutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'bn',
    'en',
    'gu',
    'hi',
    'kn',
    'ml',
    'mr',
    'or',
    'pa',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
