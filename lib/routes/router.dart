import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_app/routes/home_shell.dart';
import 'package:pay_app/screens/account/settings/screen.dart';
import 'package:pay_app/screens/account/settings/language_screen.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/state/onboarding.dart';
import 'package:pay_app/state/state.dart';
import 'package:provider/provider.dart';

// screens
import 'package:pay_app/screens/home/screen.dart';
import 'package:pay_app/screens/onboarding/screen.dart';
import 'package:pay_app/screens/account/edit/screen.dart';
import 'package:pay_app/screens/groups/screen.dart';

// state
import 'package:web3dart/web3dart.dart';

String addTimestampToUrl(String url) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  if (url.contains('?')) {
    return '$url&timestamp=$timestamp';
  }

  return '$url?timestamp=$timestamp';
}

Future<String?> redirectHandler(
    BuildContext context, GoRouterState state) async {
  final url = state.uri.toString();
  final deeplinkDomains = dotenv.get('DEEPLINK_DOMAINS').split(',');

  final connectedAccountAddress =
      context.read<OnboardingState>().connectedAccountAddress;

  for (final deeplinkDomain in deeplinkDomains) {
    if (url.contains(deeplinkDomain) && !url.contains('?deepLink=')) {
      if (connectedAccountAddress == null) {
        return '/';
      }

      // add timestamp to url to make it unique
      final uniqueUrl = addTimestampToUrl(url);
      return '/home?deepLink=${Uri.encodeComponent(uniqueUrl)}';
    }
  }

  return url;
}

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  GlobalKey<NavigatorState> appShellNavigatorKey,
  GlobalKey<NavigatorState> placeShellNavigatorKey,
  List<NavigatorObserver> observers, {
  required Config config,
  EthereumAddress? accountAddress,
}) =>
    GoRouter(
      initialLocation: accountAddress != null ? '/home' : '/',
      debugLogDiagnostics: kDebugMode,
      navigatorKey: rootNavigatorKey,
      observers: observers,
      redirect: redirectHandler,
      routes: [
        GoRoute(
          name: 'Onboarding',
          path: '/',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            return const OnboardingScreen();
          },
        ),
        ShellRoute(
          navigatorKey: appShellNavigatorKey,
          builder: (context, state, child) => HomeShell(
            key: Key('home-shell'),
            state: state,
            config: config,
            child: provideAccountState(
              context,
              state,
              config,
              child,
            ),
          ),
          routes: [
            GoRoute(
              name: 'Home',
              path: '/home',
              builder: (context, state) {
                return HomeScreen(
                  key: Key('home'),
                  accountAddress: accountAddress?.hexEip55 ?? '',
                );
              },
            ),
            GoRoute(
              name: 'MyAccountSettings',
              path: '/my-account/settings',
              builder: (context, state) {
                return MyAccountSettings(
                    accountAddress: accountAddress?.hexEip55 ?? '');
              },
              routes: [
                GoRoute(
                  name: 'LanguageSettings',
                  path: '/language',
                  builder: (context, state) {
                    return const LanguageScreen();
                  },
                ),
              ],
            ),
            GoRoute(
              name: 'EditMyAccount',
              path: '/my-account/edit',
              builder: (context, state) {
                return const EditAccountScreen();
              },
            ),
            GoRoute(
              name: 'Groups',
              path: '/groups',
              builder: (context, state) {
                return const GroupsScreen();
              },
            ),
          ],
        ),
      ],
    );
