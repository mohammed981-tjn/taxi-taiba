import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Users App'**
  String get appTitle;

  /// No description provided for @welcomeText.
  ///
  /// In en, this message translates to:
  /// **'Your Ultimate Travel Companion!'**
  String get welcomeText;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @myTrips.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTrips;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'please wait...'**
  String get pleaseWait;

  /// No description provided for @addDropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Dropoff Location?'**
  String get addDropoffLocation;

  /// No description provided for @searchDestination.
  ///
  /// In en, this message translates to:
  /// **'Search Destination'**
  String get searchDestination;

  /// No description provided for @getDriver.
  ///
  /// In en, this message translates to:
  /// **'Get Driver'**
  String get getDriver;

  /// No description provided for @driverIsArriving.
  ///
  /// In en, this message translates to:
  /// **'Driver is Arriving'**
  String get driverIsArriving;

  /// No description provided for @driverHasArrived.
  ///
  /// In en, this message translates to:
  /// **'Driver has Arrived'**
  String get driverHasArrived;

  /// No description provided for @driverIsComing.
  ///
  /// In en, this message translates to:
  /// **'Driver is Coming'**
  String get driverIsComing;

  /// No description provided for @drivingToDropoff.
  ///
  /// In en, this message translates to:
  /// **'Driving to DropOff Location'**
  String get drivingToDropoff;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @blockedMsg.
  ///
  /// In en, this message translates to:
  /// **'You are blocked. Contact admin: james.tope01@gmail.com'**
  String get blockedMsg;

  /// No description provided for @gettingDirection.
  ///
  /// In en, this message translates to:
  /// **'Getting direction...'**
  String get gettingDirection;

  /// No description provided for @noDriverAvailable.
  ///
  /// In en, this message translates to:
  /// **'NO Driver Available'**
  String get noDriverAvailable;

  /// No description provided for @noDriverFound.
  ///
  /// In en, this message translates to:
  /// **'No driver found in the nearby location. Please try again shortly.'**
  String get noDriverFound;

  /// No description provided for @pickupAddress.
  ///
  /// In en, this message translates to:
  /// **'pickup address'**
  String get pickupAddress;

  /// No description provided for @enterDestinationAddress.
  ///
  /// In en, this message translates to:
  /// **'enter destination address'**
  String get enterDestinationAddress;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Trips History'**
  String get historyTitle;

  /// No description provided for @noRecordFound.
  ///
  /// In en, this message translates to:
  /// **'No record found.'**
  String get noRecordFound;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error Occurred'**
  String get errorOccurred;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to OAGO Ride'**
  String get aboutTitle;

  /// No description provided for @oagoDescription.
  ///
  /// In en, this message translates to:
  /// **'OAGO Ride is a smart mobility platform that connects travelers with reliable drivers for daily rides, long-distance journeys, and corporate transportation. Beyond regular ride-hailing, OAGO also offers car rental services, allowing car owners to lend their vehicles to travelers. With seamless hotel booking and travel assistance, OAGO provides a one-stop solution for all your transportation needs. Whether you need a quick ride, a professional driver, or a rental car, OAGO makes travel effortless, safe, and convenient.'**
  String get oagoDescription;

  /// No description provided for @feedbackText.
  ///
  /// In en, this message translates to:
  /// **'We appreciate your feedback! Feel free to email us at james.tope01@gmail.com.'**
  String get feedbackText;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 OAGO Ride. All rights reserved.'**
  String get copyright;

  /// No description provided for @chooseRide.
  ///
  /// In en, this message translates to:
  /// **'Choose a Ride'**
  String get chooseRide;

  /// No description provided for @confirmRide.
  ///
  /// In en, this message translates to:
  /// **'Confirm Ride'**
  String get confirmRide;

  /// No description provided for @oagoGo.
  ///
  /// In en, this message translates to:
  /// **'OAGO Go'**
  String get oagoGo;

  /// No description provided for @oagoExecutive.
  ///
  /// In en, this message translates to:
  /// **'OAGO Executive'**
  String get oagoExecutive;

  /// No description provided for @oagoXL.
  ///
  /// In en, this message translates to:
  /// **'OAGO XL'**
  String get oagoXL;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up Here'**
  String get dontHaveAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login Here'**
  String get alreadyHaveAccount;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'email is not valid'**
  String get invalidEmail;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be 3 characters or more'**
  String get nameTooShort;

  /// No description provided for @phoneTooShort.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be 7 or more numbers'**
  String get phoneTooShort;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @loggedInSuccess.
  ///
  /// In en, this message translates to:
  /// **'logged-in successfully.'**
  String get loggedInSuccess;

  /// No description provided for @accountCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account Created Successfully.'**
  String get accountCreatedSuccess;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'your record do not exists as a User'**
  String get userNotFound;

  /// No description provided for @loginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to Account'**
  String get loginToAccount;

  /// No description provided for @rideWithUs.
  ///
  /// In en, this message translates to:
  /// **'Ride with Us'**
  String get rideWithUs;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @introHeadline1.
  ///
  /// In en, this message translates to:
  /// **'Your Ultimate Travel Companion!'**
  String get introHeadline1;

  /// No description provided for @introDesc1.
  ///
  /// In en, this message translates to:
  /// **'Book rides for your daily needs or hire professional drivers for long-distance journeys and corporate services—all in one app!'**
  String get introDesc1;

  /// No description provided for @introHeadline2.
  ///
  /// In en, this message translates to:
  /// **'Get a Ride Anytime, Anywhere!'**
  String get introHeadline2;

  /// No description provided for @introDesc2.
  ///
  /// In en, this message translates to:
  /// **'Need a ride? Book instantly and enjoy a comfortable journey with verified drivers!'**
  String get introDesc2;

  /// No description provided for @introHeadline3.
  ///
  /// In en, this message translates to:
  /// **'Need a Driver for a Long Trip?'**
  String get introHeadline3;

  /// No description provided for @introDesc3.
  ///
  /// In en, this message translates to:
  /// **'Going on a long journey or need a driver for your business? Hire experienced drivers with ease!'**
  String get introDesc3;

  /// No description provided for @introHeadline4.
  ///
  /// In en, this message translates to:
  /// **'Turn Your Car into an Income Source!'**
  String get introHeadline4;

  /// No description provided for @introDesc4.
  ///
  /// In en, this message translates to:
  /// **'List your car on OAGO Ride and rent it out to travelers while earning extra income!'**
  String get introDesc4;

  /// No description provided for @introHeadline5.
  ///
  /// In en, this message translates to:
  /// **'More Than Just Rides!'**
  String get introHeadline5;

  /// No description provided for @introDesc5.
  ///
  /// In en, this message translates to:
  /// **'Book hotels and find travel assistance while planning your journey—all from one app!'**
  String get introDesc5;

  /// No description provided for @introHeadline6.
  ///
  /// In en, this message translates to:
  /// **'Your Journey Begins Here!'**
  String get introHeadline6;

  /// No description provided for @introDesc6.
  ///
  /// In en, this message translates to:
  /// **'Sign up and start enjoying OAGO Ride’s amazing services today!'**
  String get introDesc6;

  /// No description provided for @rateTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your trip'**
  String get rateTripTitle;

  /// No description provided for @rateTripSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How was your ride?'**
  String get rateTripSubtitle;

  /// No description provided for @rateSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get rateSkip;

  /// No description provided for @rateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get rateSubmit;

  /// No description provided for @rateCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get rateCommentHint;

  /// No description provided for @tagCleanCar.
  ///
  /// In en, this message translates to:
  /// **'Clean car'**
  String get tagCleanCar;

  /// No description provided for @tagSafeDriving.
  ///
  /// In en, this message translates to:
  /// **'Safe driving'**
  String get tagSafeDriving;

  /// No description provided for @tagPolite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get tagPolite;

  /// No description provided for @tagOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get tagOnTime;

  /// No description provided for @tagLate.
  ///
  /// In en, this message translates to:
  /// **'Arrived late'**
  String get tagLate;

  /// No description provided for @tagRude.
  ///
  /// In en, this message translates to:
  /// **'Rude behaviour'**
  String get tagRude;

  /// No description provided for @tagUnsafe.
  ///
  /// In en, this message translates to:
  /// **'Unsafe driving'**
  String get tagUnsafe;

  /// No description provided for @tagDirtyCar.
  ///
  /// In en, this message translates to:
  /// **'Dirty car'**
  String get tagDirtyCar;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip receipt'**
  String get receiptTitle;

  /// No description provided for @receiptRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get receiptRoute;

  /// No description provided for @receiptFareDetails.
  ///
  /// In en, this message translates to:
  /// **'Fare details'**
  String get receiptFareDetails;

  /// No description provided for @receiptBaseFare.
  ///
  /// In en, this message translates to:
  /// **'Base fare'**
  String get receiptBaseFare;

  /// No description provided for @receiptDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get receiptDistance;

  /// No description provided for @receiptDuration.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get receiptDuration;

  /// No description provided for @receiptTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get receiptTotal;

  /// No description provided for @receiptDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get receiptDriver;

  /// No description provided for @receiptCar.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get receiptCar;

  /// No description provided for @receiptPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get receiptPayment;

  /// No description provided for @receiptPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get receiptPaymentCash;

  /// No description provided for @receiptNoBreakdown.
  ///
  /// In en, this message translates to:
  /// **'This trip was recorded before fare details were saved, so only the total is available.'**
  String get receiptNoBreakdown;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View receipt'**
  String get viewReceipt;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
