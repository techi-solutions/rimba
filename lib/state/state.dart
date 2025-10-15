import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/state/account.dart';
import 'package:pay_app/state/app.dart';
import 'package:pay_app/state/community.dart';
import 'package:pay_app/state/contacts/contacts.dart';
import 'package:pay_app/state/onboarding.dart';
import 'package:pay_app/state/profile.dart';
import 'package:pay_app/state/scanner.dart';
import 'package:pay_app/state/sending.dart';
import 'package:pay_app/state/topup.dart';
import 'package:pay_app/state/transactions/transactions.dart';
import 'package:pay_app/state/wallet.dart';
import 'package:pay_app/state/locale_state.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/state/groups/group_members.dart';
import 'package:pay_app/state/requests/requests.dart';
import 'package:provider/provider.dart';

Widget provideAppState(
  Config config,
  Widget? child, {
  Widget Function(BuildContext, Widget?)? builder,
}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(config),
        ),
        ChangeNotifierProvider(
          create: (_) => CommunityState(),
        ),
        ChangeNotifierProvider(
          create: (_) => OnboardingState(config),
        ),
        ChangeNotifierProvider(
          create: (_) => ScanState(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleState(),
        ),
        ChangeNotifierProvider(
          key: Key('topup'),
          create: (_) => TopupState(),
        ),
        ChangeNotifierProvider(
          key: Key('profile'),
          create: (_) => ProfileState(config),
        ),
        ChangeNotifierProvider(
          key: Key('wallet'),
          create: (_) => WalletState(config),
        ),
        // GroupsState will be provided in provideAccountState
      ],
      builder: builder,
      child: child,
    );

Widget provideAccountState(
  BuildContext context,
  GoRouterState state,
  Config config,
  Widget child,
) {
  final token = state.uri.queryParameters['token'];

  return Consumer<ProfileState>(
    builder: (context, profileState, _) {
      final account = profileState.appAccount.hexEip55;

      return MultiProvider(
        key: Key('account-$account-$token'),
        providers: [
          ChangeNotifierProvider(
            key: Key('contacts'),
            create: (_) => ContactsState(config),
          ),
          ChangeNotifierProvider(
            key: Key('account-$account'),
            create: (_) => AccountState(config),
          ),
          ChangeNotifierProvider(
            key: Key('transactions-$account-$token'),
            create: (_) => TransactionsState(accountAddress: account),
          ),
          ChangeNotifierProvider(
            key: Key('groups-$account'),
            create: (_) => GroupsState(account: account, config: config),
          ),
          ChangeNotifierProvider(
            key: Key('group-members'),
            create: (_) => GroupMembersState(),
          ),
          ChangeNotifierProvider(
            key: Key('requests'),
            create: (_) => RequestsState(),
          ),
        ],
        child: child,
      );
    },
  );
}

Widget provideWalletState(
  BuildContext context,
  Config config,
  String account,
  Widget child,
) {
  return MultiProvider(
    key: Key('account-$account'),
    providers: [
      ChangeNotifierProvider(
        key: Key('wallet-$account'),
        create: (_) => WalletState(config),
      ),
    ],
    child: child,
  );
}

Widget provideSendingState(
  BuildContext context,
  Config config,
  String initialAddress,
  Widget child,
) {
  return MultiProvider(
    key: Key('sending-$initialAddress'),
    providers: [
      ChangeNotifierProvider(
        key: Key('wallet-$initialAddress'),
        create: (_) => WalletState(config),
      ),
      ChangeNotifierProvider(
        key: Key('sending-$initialAddress'),
        create: (_) => SendingState(
          config: config,
          initialAddress: initialAddress,
        ),
      ),
    ],
    child: child,
  );
}
