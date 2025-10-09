import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_app/l10n/app_localizations.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/state/topup.dart';
import 'package:pay_app/state/wallet.dart';
import 'package:pay_app/theme/colors.dart';
import 'package:pay_app/utils/delay.dart';
import 'package:pay_app/widgets/toast/toast.dart';
import 'package:pay_app/widgets/webview/connected_webview_modal.dart';
import 'package:pay_app/widgets/modals/topup_coming_soon_modal.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class HomeShell extends StatefulWidget {
  final Widget child;
  final GoRouterState state;
  final Config config;

  const HomeShell({
    super.key,
    required this.child,
    required this.state,
    required this.config,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late TopupState _topupState;
  late WalletState _walletState;

  bool _pauseDeepLinkHandling = false;

  String? _deepLink;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _topupState = context.read<TopupState>();
      _walletState = context.read<WalletState>();
    });
  }

  void handleDismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void handleTopUp(String baseUrl) async {
    await _topupState.generateTopupUrl(baseUrl);

    if (!mounted) {
      return;
    }

    HapticFeedback.heavyImpact();

    final redirectDomain = dotenv.env['APP_REDIRECT_DOMAIN'];

    final redirectUrl = redirectDomain != null ? 'https://$redirectDomain' : '';

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      barrierColor: blackColor.withAlpha(160),
      builder: (modalContext) {
        final topupUrl =
            modalContext.select((TopupState state) => state.topupUrl);

        if (topupUrl.isEmpty) {
          return const TopupComingSoonModal();
        }

        return ConnectedWebViewModal(
          modalKey: 'connected-webview',
          url: topupUrl,
          redirectUrl: redirectUrl,
        );
      },
    );

    if (result == null) {
      return;
    }

    if (!result.startsWith(redirectUrl)) {
      return;
    }

    if (!mounted) {
      return;
    }

    HapticFeedback.heavyImpact();

    toastification.showCustom(
      context: context,
      autoCloseDuration: const Duration(seconds: 5),
      alignment: Alignment.bottomCenter,
      builder: (context, toast) => Toast(
        icon: const Text('🚀'),
        title: Text(AppLocalizations.of(context)!.topupOnWay),
      ),
    );

    await _walletState.updateBalance();
  }

  Future<void> handleDeepLink(String? deepLink) async {
    if (deepLink != null && !_pauseDeepLinkHandling) {
      _pauseDeepLinkHandling = true;

      await delay(const Duration(milliseconds: 100));

      if (!mounted) {
        return;
      }

      // await handleQRScan(
      //   context,
      //   () {},
      //   manualResult: deepLink,
      // );

      _pauseDeepLinkHandling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deepLink = widget.state.uri.queryParameters['deepLink'];

    if (_deepLink != deepLink && deepLink != null) {
      handleDeepLink(deepLink);
    }
    _deepLink = deepLink;

    return widget.child;
  }
}
