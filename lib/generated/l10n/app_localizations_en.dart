// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AlertContact';

  @override
  String get welcome => 'Welcome';

  @override
  String get signInOrRegister => 'Sign in or register and we’ll get started.';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get register => 'Register';

  @override
  String get notAMember => 'Not a member?';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get createAccount => 'Create Account';

  @override
  String get pleaseAcceptTerms => 'Please accept the terms and conditions';

  @override
  String get createYourAccount => 'Create your account';

  @override
  String get registerSubtitle => 'Register to get started.';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Email is invalid';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordMatch => 'Passwords do not match';

  @override
  String get passwordStrength =>
      'Password must contain at least 1 uppercase letter, 1 number and 1 special character';

  @override
  String get passwordSpecialChar =>
      'Password must contain at least 1 special character';

  @override
  String get passwordCapitalLetter =>
      'Password must contain at least 1 uppercase letter';

  @override
  String get passwordNumber => 'Password must contain at least 1 number';

  @override
  String get invalidEmail => 'Email is invalid';

  @override
  String get fullName => 'Full Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get nameTooShort => 'Name must be at least 2 characters';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get confirmPasswordRequired => 'Confirm password is required';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordHintShort => 'Min 6 characters';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get iAgreeWith => 'I agree with';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get and => 'and';

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get dangerZones => 'Danger Zones';

  @override
  String get safeZones => 'Safe Zones';

  @override
  String get contacts => 'Contacts';

  @override
  String get alerts => 'Alerts';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get addContact => 'Add Contact';

  @override
  String get createDangerZone => 'Create Danger Zone';

  @override
  String get createSafeZone => 'Create Safe Zone';

  @override
  String get sendAlert => 'Send Alert';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get noData => 'No data available';

  @override
  String get retry => 'Retry';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get locationPermission => 'Location Permission';

  @override
  String get notificationPermission => 'Notification Permission';

  @override
  String get phonePermission => 'Phone Permission';

  @override
  String get allow => 'Allow';

  @override
  String get deny => 'Deny';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get onBoardingSlide_title_1 => 'Your security. Your serenity.';

  @override
  String get onBoardingSlide_body_1 =>
      'Anticipate risks around you and watch over those who matter — simply, without stress.';

  @override
  String get onBoardingSlide_title_2 => 'Avoid dangerous zones';

  @override
  String get onBoardingSlide_body_2 =>
      'Immediate alert when you approach a reported place (theft, assault, accident).';

  @override
  String get onBoardingSlide_title_3 => 'Create safe zones';

  @override
  String get onBoardingSlide_body_3 =>
      'Home, school, commute… Receive a notification if a relative leaves the zone.';

  @override
  String get onBoardingSlide_title_4 => 'Your relatives, your rules';

  @override
  String get onBoardingSlide_body_4 =>
      'Becoming \"relatives\" doesn\'t mean being followed: you decide, no one else.';

  @override
  String get onBoardingStart => 'Start';

  @override
  String get onBoardingNext => 'Next';

  @override
  String get onBoardingSkip => 'Skip';

  @override
  String get emailVerificationTitle => 'Verify your email';

  @override
  String get emailVerificationDescription =>
      'We\'ve sent a verification link to your email address. Click the link to activate your account.';

  @override
  String get emailVerificationAutoCheck =>
      'Automatic verification in progress...';

  @override
  String get resendEmail => 'Resend email';

  @override
  String resendEmailIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get checkNow => 'Check now';

  @override
  String get emailNotFound => 'Can\'t find the email?';

  @override
  String get emailVerificationResend => 'Resend email';

  @override
  String emailVerificationResendCooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get emailVerificationCheckNow => 'Check now';

  @override
  String get emailVerificationNotFound => 'Can\'t find the email?';

  @override
  String get emailTroubleshootingTips =>
      '• Check your spam folder\n• Make sure the email address is correct\n• The email may take a few minutes to arrive';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordDescription =>
      'Enter your email address to receive a reset link.';

  @override
  String get forgotPasswordEmailSent =>
      'A reset email has been sent to your address. Check your inbox and follow the instructions.';

  @override
  String get checkEmailTitle => 'Check your email';

  @override
  String get checkEmailDescription =>
      'We\'ve sent a reset link to your email address.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resendResetEmail => 'Resend email';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get resetEmailSentSuccess => 'Reset email sent successfully';

  @override
  String get resetEmailError => 'An error occurred';
}
