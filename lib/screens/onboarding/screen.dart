import 'package:country_flags/country_flags.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:rimba/state/community.dart';
import 'package:rimba/state/onboarding.dart';
import 'package:rimba/theme/colors.dart';
import 'package:rimba/utils/delay.dart';
import 'package:rimba/widgets/coin_logo.dart';
import 'package:rimba/widgets/wide_button.dart';
import 'package:rimba/widgets/text_field.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rimba/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late OnboardingState _onboardingState;
  late CommunityState _communityState;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onboardingState = context.read<OnboardingState>();
      _communityState = context.read<CommunityState>();
      onLoad();
    });
  }

  // Add a focus node
  final FocusNode _focusNode = FocusNode();
  final FocusNode _challengeFocusNode = FocusNode();

  String? _previousChallenge;
  bool _navigating = false;

  void onLoad() async {
    final navigator = GoRouter.of(context);

    await _onboardingState.init();
    await _communityState.fetchCommunity();

    final account = await _onboardingState.isSessionExpired();
    if (account != null) {
      navigator.go('/${account.hexEip55}');
      return;
    }

    // Start the animation
    _animationController.forward().then((_) {
      // Focus the text field after animation completes
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void handleRequest(String email) async {
    await _onboardingState.requestSession(email);
    _onboardingState.updateOTP(null);

    await delay(const Duration(milliseconds: 100));

    _challengeFocusNode.requestFocus();
  }

  void handleConfirm(String otp) async {
    final navigator = GoRouter.of(context);

    await delay(const Duration(milliseconds: 50));

    final account = await _onboardingState.confirmSession(otp);

    if (account != null && !_navigating) {
      _navigating = true;
      _onboardingState.reset();
      navigator.go('/${account.hexEip55}');
    }
  }

  void handleTermsAndConditions() {
    launchUrl(
      Uri.parse('https://www.pay.brussels/terms-and-conditions'),
      mode: LaunchMode.inAppWebView,
    );
  }

  void handleRetry() {
    _onboardingState.retry();
  }

  void handleEmailChange(String email) {
    _onboardingState.validateEmail(email);
  }

  void handleOTPChange(String otp) {
    _onboardingState.updateOTP(otp);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final theme = CupertinoTheme.of(context);
    final primaryColor = theme.primaryColor;

    final community = context.select((CommunityState state) => state.community);

    final sessionRequestStatus =
        context.select((OnboardingState state) => state.sessionRequestStatus);

    final emailController =
        context.read<OnboardingState>().emailController;
    final otpController =
        context.read<OnboardingState>().otpController;

    final otp =
        context.select((OnboardingState state) => state.otp);

    final emailTouched = context.select((OnboardingState state) => state.emailTouched);
    final isValidEmail = context.select((OnboardingState state) => state.isValidEmail);

    final otpTouched =
        context.select((OnboardingState state) => state.otpTouched);

    final isValidOTP = otp != null && otp.length == 6;

    if (otp != _previousChallenge && isValidOTP) {
      handleConfirm(otp);
    }
    _previousChallenge = otp;

    return CupertinoPageScaffold(
      backgroundColor: whiteColor,
      child: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // Top content in an Expanded to push it to the center
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      CoinLogo(size: 140),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        community?.community.name ??
                            AppLocalizations.of(context)!.loading,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        community?.community.description ??
                            AppLocalizations.of(context)!.loading,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textMutedColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Bottom content with fade animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.bySigningIn,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textMutedColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: handleTermsAndConditions,
                            child: Text(
                              AppLocalizations.of(context)!.termsAndConditions,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textMutedColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            '.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textMutedColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Email Input
                      if (sessionRequestStatus == SessionRequestStatus.none ||
                          sessionRequestStatus ==
                              SessionRequestStatus.pending ||
                          sessionRequestStatus == SessionRequestStatus.failed)
                        CustomTextField(
                          controller: emailController,
                          placeholder: AppLocalizations.of(context)!
                              .emailPlaceholder,
                          focusNode: _focusNode, // Use the focus node
                          autofocus:
                              false, // We'll focus manually after animation
                          enabled:
                              sessionRequestStatus == SessionRequestStatus.none,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: !emailTouched
                                  ? mutedColor
                                  : emailTouched && isValidEmail
                                      ? (sessionRequestStatus ==
                                              SessionRequestStatus.pending
                                          ? transparentColor
                                          : primaryColor)
                                      : warningColor,
                            ),
                          ),
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 22,
                            color: sessionRequestStatus ==
                                    SessionRequestStatus.pending
                                ? textMutedColor
                                : textColor,
                            fontWeight: emailTouched && isValidEmail
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 1,
                          ),
                          placeholderStyle: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: textMutedColor,
                            letterSpacing: 1,
                          ),
                          prefix: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              height: 40,
                              width: 40,
                              child: Icon(
                                CupertinoIcons.mail,
                                color: iconColor,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: handleEmailChange,
                        ),
                      //   OTP Input
                      if (sessionRequestStatus ==
                              SessionRequestStatus.challenge ||
                          sessionRequestStatus ==
                              SessionRequestStatus.confirming ||
                          sessionRequestStatus ==
                              SessionRequestStatus.confirmFailed)
                        CustomTextField(
                          controller: otpController,
                          placeholder:
                              AppLocalizations.of(context)!.enterLoginCode,
                          focusNode: _challengeFocusNode, // Use the focus node
                          autofocus:
                              false, // We'll focus manually after animation
                          enabled: sessionRequestStatus ==
                                  SessionRequestStatus.challenge ||
                              sessionRequestStatus ==
                                  SessionRequestStatus.confirmFailed,
                          maxLength: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: !otpTouched
                                  ? mutedColor
                                  : otpTouched && isValidOTP
                                      ? (sessionRequestStatus ==
                                              SessionRequestStatus.confirming
                                          ? transparentColor
                                          : primaryColor)
                                      : warningColor,
                            ),
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            color: sessionRequestStatus ==
                                    SessionRequestStatus.confirming
                                ? textMutedColor
                                : textColor,
                            fontWeight: otpTouched && isValidOTP
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 2,
                          ),
                          placeholderStyle: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            color: textMutedColor,
                            letterSpacing: 2,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: handleOTPChange,
                        ),
                      const SizedBox(height: 16),
                      if (sessionRequestStatus ==
                          SessionRequestStatus.confirmFailed)
                        Text(
                          AppLocalizations.of(context)!.invalidCode,
                          style: TextStyle(
                            color: dangerColor,
                          ),
                        ),
                      if (sessionRequestStatus ==
                          SessionRequestStatus.confirmFailed)
                        const SizedBox(
                          height: 16,
                        ),

                      // Confirm Button
                      if (sessionRequestStatus == SessionRequestStatus.none ||
                          sessionRequestStatus ==
                              SessionRequestStatus.pending ||
                          sessionRequestStatus == SessionRequestStatus.failed)
                        WideButton(
                          disabled: !isValidEmail ||
                              sessionRequestStatus ==
                                  SessionRequestStatus.pending,
                          onPressed: isValidEmail
                              ? () => handleRequest(
                                  emailController.value.text)
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                sessionRequestStatus ==
                                        SessionRequestStatus.pending
                                    ? AppLocalizations.of(context)!
                                        .sendingEmailCode
                                    : AppLocalizations.of(context)!.confirm,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: sessionRequestStatus ==
                                          SessionRequestStatus.pending
                                      ? primaryColor.withAlpha(180)
                                      : CupertinoColors.white,
                                ),
                              ),
                              if (sessionRequestStatus ==
                                  SessionRequestStatus.pending)
                                const SizedBox(width: 8),
                              if (sessionRequestStatus ==
                                  SessionRequestStatus.pending)
                                CupertinoActivityIndicator(
                                  color: primaryColor.withAlpha(180),
                                ),
                            ],
                          ),
                        ),
                      // Challenge Confirm Button
                      if (sessionRequestStatus ==
                              SessionRequestStatus.challenge ||
                          sessionRequestStatus ==
                              SessionRequestStatus.confirming ||
                          sessionRequestStatus ==
                              SessionRequestStatus.confirmFailed)
                        WideButton(
                          disabled: !isValidOTP ||
                              sessionRequestStatus ==
                                  SessionRequestStatus.confirming,
                          onPressed: isValidOTP
                              ? () =>
                                  handleConfirm(otpController.value.text)
                              : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                sessionRequestStatus ==
                                        SessionRequestStatus.confirming
                                    ? AppLocalizations.of(context)!.loggingIn
                                    : sessionRequestStatus ==
                                            SessionRequestStatus.confirmFailed
                                        ? AppLocalizations.of(context)!
                                            .confirmCodeAgain
                                        : AppLocalizations.of(context)!
                                            .confirmCode,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: sessionRequestStatus ==
                                          SessionRequestStatus.confirming
                                      ? primaryColor.withAlpha(180)
                                      : CupertinoColors.white,
                                ),
                              ),
                              if (sessionRequestStatus ==
                                  SessionRequestStatus.confirming)
                                const SizedBox(width: 8),
                              if (sessionRequestStatus ==
                                  SessionRequestStatus.confirming)
                                CupertinoActivityIndicator(
                                  color: primaryColor.withAlpha(180),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (sessionRequestStatus ==
                          SessionRequestStatus.confirmFailed)
                        WideButton(
                          onPressed: handleRetry,
                          color: whiteColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.sendNewCode,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (sessionRequestStatus ==
                          SessionRequestStatus.confirmFailed)
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
