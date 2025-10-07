import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_app/models/order.dart';
import 'package:pay_app/routes/home_shell.dart';
import 'package:pay_app/screens/account/settings/screen.dart';
import 'package:pay_app/screens/account/settings/language_screen.dart';
import 'package:pay_app/screens/interactions/place/order/screen.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/state/onboarding.dart';
import 'package:pay_app/state/profile.dart';
import 'package:pay_app/state/state.dart';
import 'package:provider/provider.dart';

// screens
import 'package:pay_app/screens/home/screen.dart';
import 'package:pay_app/screens/onboarding/screen.dart';
import 'package:pay_app/screens/account/edit/screen.dart';
import 'package:pay_app/screens/interactions/place/screen.dart';
import 'package:pay_app/screens/interactions/place/menu/screen.dart';
import 'package:pay_app/screens/interactions/user/screen.dart';

// state
import 'package:pay_app/state/transactions_with_user/transactions_with_user.dart';
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
        GoRoute(
          name: 'CardOrder',
          path: '/order/:orderId',
          builder: (context, state) {
            final order = state.extra! as Order;

            return OrderScreen(order: order);
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
            ShellRoute(
              navigatorKey: placeShellNavigatorKey,
              builder: (context, state, child) => Consumer<ProfileState>(
                builder: (context, profileState, _) => providePlaceState(
                  context,
                  config,
                  state.pathParameters['slug']!,
                  profileState.appAccount.hexEip55,
                  child,
                ),
              ),
              routes: [
                GoRoute(
                  name: 'InteractionWithPlace',
                  path: '/place/:slug',
                  builder: (context, state) {
                    final slug = state.pathParameters['slug']!;

                    return InteractionWithPlaceScreen(
                      slug: slug,
                      myAddress: accountAddress?.hexEip55 ?? '',
                    );
                  },
                  routes: [
                    GoRoute(
                      name: 'PlaceMenu',
                      path: '/menu',
                      builder: (context, state) {
                        return const PlaceMenuScreen();
                      },
                    ),
                    GoRoute(
                      name: 'PlaceOrder',
                      path: '/order/:orderId',
                      builder: (context, state) {
                        final order = state.extra! as Order;

                        return OrderScreen(order: order);
                      },
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              name: 'InteractionWithUser',
              path: '/user/:withUser',
              builder: (context, state) {
                final userAddress = state.pathParameters['withUser']!;

                final extra = state.extra as Map<String, dynamic>;

                final customName = extra['name'] ?? '';
                final customPhone = extra['phone'] ?? '';
                final customPhoto = extra['photo'] as Uint8List?;
                final customImageUrl = extra['imageUrl'] as String?;

                return ChangeNotifierProvider(
                  create: (_) => TransactionsWithUserState(
                    withUserAddress: userAddress,
                    myAddress: accountAddress?.hexEip55 ?? '',
                  ),
                  child: InteractionWithUserScreen(
                    customName: customName,
                    customPhone: customPhone,
                    customPhoto: customPhoto,
                    customImageUrl: customImageUrl,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
