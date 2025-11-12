import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/state/app.dart';
import 'package:pay_app/state/profile.dart';
import 'package:pay_app/state/wallet.dart';
import 'package:pay_app/theme/colors.dart';
import 'package:pay_app/widgets/blurry_child.dart';
import 'package:pay_app/widgets/cards/card.dart' as cardWidget;
import 'package:pay_app/widgets/cards/card_skeleton.dart';
import 'package:pay_app/widgets/coin_logo.dart';
import 'package:pay_app/widgets/toast/toast.dart';
import 'package:pay_app/widgets/webview/connected_webview_modal.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class ProfileBar extends StatefulWidget {
  final String? selectedAddress;
  final void Function(String)? onCardChanged;
  final PageController? pageController;
  final bool small;
  final Config config;
  final bool loading;
  final String accountAddress;
  final Color backgroundColor;
  final Function(String) onTopUpTap;
  final Function()? onAddCard;

  const ProfileBar({
    super.key,
    this.selectedAddress,
    this.onCardChanged,
    this.pageController,
    required this.small,
    required this.config,
    required this.loading,
    required this.accountAddress,
    required this.backgroundColor,
    required this.onTopUpTap,
    this.onAddCard,
  });

  @override
  State<ProfileBar> createState() => _ProfileBarState();
}

class _ProfileBarState extends State<ProfileBar> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  Future<void> handleEditProfile() async {
    final navigator = GoRouter.of(context);
    HapticFeedback.heavyImpact();

    navigator.push('/my-account/edit');
  }

  Future<void> handleSettings() async {
    final navigator = GoRouter.of(context);
    HapticFeedback.heavyImpact();

    navigator.push('/my-account/settings');
  }

  Future<void> handleMoneriumConnect() async {
    HapticFeedback.mediumImpact();

    final walletState = context.read<WalletState>();

    try {
      // Build auth URL with PKCE (handled in wallet state)
      final authData = await walletState.buildMoneriumAuthUrl();
      final authUrl = authData['authUrl']!;
      final redirectUrl = authData['redirectUri']!;
      print('authUrl: $authUrl');
      print('redirectUrl: $redirectUrl');

      if (!mounted) {
        return;
      }

      final path = await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: true,
        useRootNavigator: false,
        barrierColor: blackColor.withAlpha(160),
        builder: (modalContext) {
          return ConnectedWebViewModal(
            modalKey: 'monerium-connect',
            url: authUrl,
            redirectUrl: redirectUrl,
          );
        },
      );

      if (path == null || !mounted) {
        return;
      }

      // display success toast
      toastification.showCustom(
        context: context,
        autoCloseDuration: const Duration(seconds: 5),
        alignment: Alignment.bottomCenter,
        builder: (context, toast) => Toast(
          icon: const Text('🚀'),
          title: Text('Monerium connected successfully'),
        ),
      );
    } catch (e) {
      debugPrint('Error starting Monerium connect: $e');
      // TODO: Show error to user
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenConfig = context.select<AppState, TokenConfig>(
      (state) => state.currentTokenConfig,
    );

    final balance = context.select<WalletState, String>(
      (state) => state.tokenBalances[tokenConfig.address] ?? '0.0',
    );
    final config = widget.config;

    final topUpPlugin = config.getTopUpPlugin(
      tokenAddress: tokenConfig.address,
    );

    return _buildProfileCard(
      context,
      balance,
      config,
      tokenConfig,
      topUpPlugin,
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    String balance,
    Config? config,
    TokenConfig? tokenConfig,
    PluginConfig? topUpPlugin,
  ) {
    final safeArea = MediaQuery.of(context).padding;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final adjustedWidth = widget.small ? width * 0.8 : width;

    final primaryColor = context.select<AppState, Color>(
      (state) => state.tokenPrimaryColor,
    );

    final appProfile = context.watch<ProfileState>().appProfile;

    double cardWidth = adjustedWidth * 0.8;

    double containerHeight = widget.small
        ? (height * 0.35).clamp(240.0, 280.0)
        : (height * 0.4).clamp(280.0, 320.0);

    return BlurryChild(
      child: Container(
        width: width,
        height: containerHeight,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: blackColor.withAlpha(40),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: safeArea.top),
            if (appProfile.isAnonymous)
              CardSkeleton(
                width: cardWidth,
                color: primaryColor,
              ),
            if (!appProfile.isAnonymous)
              SizedBox(
                height: containerHeight - safeArea.top - 20,
                width: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Center(
                    child: cardWidget.Card(
                      width: cardWidth,
                      uid: 'main',
                      color: primaryColor,
                      profile: appProfile,
                      usernamePrefix: '@',
                      icon: CupertinoIcons.device_phone_portrait,
                      onTopUpPressed:
                          !widget.loading ? handleMoneriumConnect : null,
                      onCardNameTapped: handleEditProfile,
                      onCardPressed: null,
                      onCardBalanceTapped: null,
                      logo: tokenConfig?.logo,
                      balance: balance,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Name extends StatelessWidget {
  final String name;

  const Name({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class Balance extends StatelessWidget {
  final String balance;
  final String? logo;

  const Balance({super.key, required this.balance, this.logo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CoinLogo(size: 33, logo: logo),
        SizedBox(width: 4),
        Text(
          balance,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TopUpButton extends StatelessWidget {
  final Function() onTopUpTap;

  const TopUpButton({super.key, required this.onTopUpTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.select<AppState, Color>(
      (state) => state.tokenPrimaryColor,
    );

    return CupertinoButton(
      padding: EdgeInsets.zero,
      color: primaryColor,
      borderRadius: BorderRadius.circular(8),
      minSize: 0,
      onPressed: onTopUpTap,
      child: SizedBox(
        width: 70,
        height: 28,
        child: Center(
          child: Text(
            '+ top up',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
