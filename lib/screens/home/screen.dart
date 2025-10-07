import 'package:collection/collection.dart';
import 'package:dart_debouncer/dart_debouncer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'package:rimba/models/order.dart';
import 'package:rimba/models/card.dart';
import 'package:rimba/screens/home/contact_list_item.dart';
import 'package:rimba/screens/home/profile_list_item.dart';
import 'package:rimba/screens/home/profile_modal.dart';
import 'package:rimba/screens/home/transaction_list_item.dart';
import 'package:rimba/models/simple_lending_group.dart';
import 'package:rimba/services/preferences/preferences.dart';
import 'package:rimba/services/config/config.dart';
import 'package:rimba/state/app.dart';
import 'package:rimba/state/cards.dart';
import 'package:rimba/state/contacts/contacts.dart';
import 'package:rimba/state/contacts/selectors.dart';
import 'package:rimba/state/simple_lending_state.dart';
import 'package:rimba/state/onboarding.dart';
import 'package:rimba/state/places/places.dart';
import 'package:rimba/state/state.dart';
import 'package:rimba/state/topup.dart';
import 'package:rimba/state/transactions/transactions.dart';
import 'package:rimba/state/wallet.dart';
import 'package:rimba/state/profile.dart';
import 'package:rimba/theme/colors.dart';
import 'package:rimba/widgets/cards/card.dart' as card_widget;
import 'package:rimba/widgets/cards/card_skeleton.dart';
import 'package:rimba/services/wallet/contracts/profile.dart';
import 'package:rimba/utils/delay.dart';
import 'package:rimba/widgets/modals/confirm_modal.dart';
import 'package:rimba/screens/home/scanner_modal/scanner_modal.dart';
import 'package:rimba/widgets/toast/toast.dart';
import 'package:rimba/widgets/webview/connected_webview_modal.dart';
import 'package:rimba/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'package:universal_io/io.dart';
import 'package:web3dart/web3dart.dart';
import 'package:rimba/models/transaction.dart' as tx;

import 'search_bar.dart';

class HomeScreen extends StatefulWidget {
  final String accountAddress;

  const HomeScreen({
    super.key,
    required this.accountAddress,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _cardScrollController = ScrollController();

  bool isKeyboardVisible = false;
  bool isSearching = false;

  double _scrollOffset = 0.0;
  final double _maxScrollOffset = 100.0;

  final Debouncer _debouncer =
      Debouncer(timerDuration: const Duration(milliseconds: 300));

  late AppState _appState;
  late OnboardingState _onboardingState;
  late PlacesState _placesState;
  late WalletState _walletState;
  late ContactsState _contactsState;
  late TopupState _topupState;
  late CardsState _cardsState;
  late TransactionsState _transactionsState;
  late ProfileState _profileState; // Used in _buildCardWidget method
  late SimpleLendingState _simpleLendingState;

  bool _handlingExpiredCredentials = false;
  bool _stopInitRetries = false;

  late AnimationController _backgroundColorController;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();

    _initState();

    _backgroundColorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _backgroundColorAnimation = ColorTween(
      begin: whiteColor,
      end: blackColor,
    ).animate(CurvedAnimation(
      parent: _backgroundColorController,
      curve: Curves.easeInOut,
    ));

    _searchFocusNode.addListener(_searchListener);
    _scrollController.addListener(_scrollListener);
    _cardScrollController.addListener(_cardScrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Start listening to lifecycle changes.
      WidgetsBinding.instance.addObserver(this);
      await onLoad();
    });
  }

  void _initState() {
    _appState = context.read<AppState>();
    _onboardingState = context.read<OnboardingState>();
    _placesState = context.read<PlacesState>();
    _walletState = context.read<WalletState>();
    _contactsState = context.read<ContactsState>();
    _topupState = context.read<TopupState>();
    _cardsState = context.read<CardsState>();
    _transactionsState = context.read<TransactionsState>();
    _profileState = context.read<ProfileState>();
    _simpleLendingState = SimpleLendingState();
    _simpleLendingState.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> onLoad() async {
    if (_stopInitRetries) {
      return;
    }

    final connectedAccountAddress =
        context.read<OnboardingState>().connectedAccountAddress;
    if (connectedAccountAddress == null) {
      await delay(const Duration(milliseconds: 2000));
      return onLoad();
    }

    final currentTokenAddress = context.read<AppState>().currentTokenAddress;

    // Initialize simple lending groups (local data only)
    _simpleLendingState.initialize();
    _cardsState.fetchCards(tokenAddress: currentTokenAddress);

    // Initialize transactions for the current account
    if (widget.accountAddress.isNotEmpty) {
      _transactionsState.getTransactions(token: currentTokenAddress);
    }
  }

  Future<void> handleRefresh() async {
    HapticFeedback.lightImpact();

    // Refresh simple lending groups
    _simpleLendingState.refresh();

    // Refresh transactions as well
    await _transactionsState.refreshTransactions();

    HapticFeedback.heavyImpact();
  }

  void handleExpiredCredentials() {
    if (_handlingExpiredCredentials) {
      return;
    }

    _handlingExpiredCredentials = true;

    final navigator = GoRouter.of(context);

    _onboardingState.clearConnectedAccountAddress();
    navigator.go('/');
    return;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        _stopInitRetries = false;
        onLoad();
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        _stopInitRetries = true;
        // Interaction polling removed
    }
  }

  @override
  void dispose() {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);

    _stopInitRetries = true;

    _debouncer.dispose();

    // Interaction polling removed

    _searchFocusNode.removeListener(_searchListener);
    _searchFocusNode.dispose();

    _searchController.dispose();

    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    _cardScrollController.removeListener(_cardScrollListener);
    _cardScrollController.dispose();

    _backgroundColorController.dispose();

    _simpleLendingState.dispose();

    super.dispose();
  }

  void _searchListener() async {
    if (_searchFocusNode.hasFocus) {
      if (Platform.isAndroid) {
        if (PreferencesService().contactPermission == null) {
          final confirmed = await showCupertinoModalPopup<bool>(
            context: context,
            barrierDismissible: true,
            barrierColor: blackColor.withAlpha(160),
            builder: (modalContext) => ConfirmModal(
              title: AppLocalizations.of(context)!.displayContacts,
              details: [
                'This app uses your contact list to help you search for the right person.',
                'No contact data is sent to our servers.',
                'We generate the account number on device.',
              ],
              cancelText: AppLocalizations.of(context)!.skip,
              confirmText: AppLocalizations.of(context)!.allow,
            ),
          );

          PreferencesService().setContactPermission(confirmed ?? false);
        }

        final hasPermission = PreferencesService().contactPermission;

        if (hasPermission == true) {
          _contactsState.fetchContacts();
        }
      } else {
        _contactsState.fetchContacts();
      }
      setState(() {
        isKeyboardVisible = true;
        isSearching = true;
      });
    }

    if (!_searchFocusNode.hasFocus) {
      setState(() {
        isKeyboardVisible = false;
      });
    }
  }

  void _scrollListener() {
    // Hide on scroll down
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      setState(() {
        _scrollOffset = _scrollController.offset.clamp(0, _maxScrollOffset);
      });

      _searchFocusNode.unfocus();
    }

    // Show on scroll up
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      setState(() {
        _scrollOffset = 0;
      });
    }

    _appState.setSmall(_scrollOffset == 100);
  }

  void _cardScrollListener() {
    // Check if we're near the bottom of the scroll view
    if (_cardScrollController.position.pixels >=
        _cardScrollController.position.maxScrollExtent - 200) {
      // Load more transactions when user scrolls near the bottom
      if (!_transactionsState.loadingMore &&
          _transactionsState.hasMoreTransactions) {
        _transactionsState.loadMoreTransactions();
      }
    }
  }



  Future<void> handleProfileTap(
    String myAddress, {
    String? tokenAddress,
  }) async {
    _searchFocusNode.unfocus();

    _stopInitRetries = true;

    _backgroundColorController.forward();

    HapticFeedback.heavyImpact();

    final account = await showCupertinoDialog<EthereumAddress?>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: false,
      builder: (modalContext) => ProfileModal(
        accountAddress: myAddress,
        tokenAddress: tokenAddress,
      ),
    );

    if (account != null && mounted) {
      _walletState.setLastAccount(account.hexEip55);

      final navigator = GoRouter.of(context);

      navigator.replace('/${account.hexEip55}');
    }

    _backgroundColorController.reverse();

    _stopInitRetries = false;

    clearSearch();
  }

  void handleTopUp(String baseUrl) async {
    _stopInitRetries = true;

    await _topupState.generateTopupUrl(baseUrl);

    if (!mounted) {
      _stopInitRetries = false;
      return;
    }

    _backgroundColorController.forward();

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
          return const SizedBox.shrink();
        }

        return ConnectedWebViewModal(
          modalKey: 'connected-webview',
          url: topupUrl,
          redirectUrl: redirectUrl,
        );
      },
    );

    _stopInitRetries = false;

    _backgroundColorController.reverse();

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

  Future<void> handleQRScan(
    BuildContext context,
    String myAddress,
    Function() callback, {
    String? manualResult,
  }) async {
    _stopInitRetries = true;

    _backgroundColorController.forward();

    final tokenAddress = context.read<AppState>().currentTokenAddress;

    final selectedAccount = await showCupertinoDialog<String?>(
      context: context,
      useRootNavigator: false,
      builder: (modalContext) => provideSendingState(
        context,
        _walletState.config,
        myAddress,
        ScannerModal(
          modalKey: 'home-qr-sending',
          tokenAddress: tokenAddress,
          manualScanResult: manualResult,
        ),
      ),
    );

    if (selectedAccount != null && context.mounted) {
      final navigator = GoRouter.of(context);

      navigator.replace('/$selectedAccount');
    }

    _backgroundColorController.reverse();

    callback();

    _stopInitRetries = false;
  }

  void clearSearch() async {
    setState(() {
      isSearching = false;
    });

    _searchController.clear();
    _searchFocusNode.unfocus();

    await delay(const Duration(milliseconds: 500));

    _placesState.clearSearch();
    _contactsState.clearSearch();
  }

  void handleSearch(String query) {
    _debouncer.resetDebounce(() {
      _placesState.setSearchQuery(query);
      _contactsState.setSearchQuery(query);
    });
  }


  void handleTransactionTap(
    String? myAddress,
    tx.Transaction transaction,
    Order? order,
  ) {
    final navigator = GoRouter.of(context);

    if (order != null) {
      navigator.push('/$myAddress/place/${order.place.slug}/order/${order.id}',
          extra: order);
    } else {
      // navigator.push('/$myAddress/transaction/${transaction.id}');
    }
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Widget _buildCardWidget(BuildContext context, String? myAddress) {
    if (myAddress == null) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    final primaryColor = context.select<AppState, Color>(
      (state) => state.tokenPrimaryColor,
    );
    
    final cards = context.watch<CardsState>().cards;
    final cardBalances = context.watch<CardsState>().cardBalances;
    final appProfile = context.watch<ProfileState>().appProfile;
    final updatingCardName = context.watch<CardsState>().updatingCardName;
    
    final tokenConfig = context.select<AppState, TokenConfig>(
      (state) => state.currentTokenConfig,
    );
    
    final balance = context.select<WalletState, String>(
      (state) => state.tokenBalances[tokenConfig.address] ?? '0.0',
    );

    // Create list of all cards (app profile + card profiles)
    final List<CardInfo> cardInfoList = [
      CardInfo(
        uid: 'main',
        account: appProfile.account,
        profile: appProfile,
        balance: balance,
        project: 'main',
      ),
      ...cards.map(
        (card) {
          return CardInfo(
            uid: card.uid,
            account: card.account,
            profile: ProfileV1.cardProfile(card.account, card.uid),
            balance: cardBalances[card.account] ?? '0.0',
            project: card.project,
          );
        },
      ),
    ];

    // Find the current card (first one for now, can be made dynamic later)
    final currentCard = cardInfoList.isNotEmpty ? cardInfoList.first : null;
    
    if (currentCard == null) return const SizedBox.shrink();
    
    final isAppAccount = appProfile.account == currentCard.account;
    double cardWidth = width * 0.85;

    if (appProfile.isAnonymous || updatingCardName) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: CardSkeleton(
          width: cardWidth,
          color: primaryColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: card_widget.Card(
          width: cardWidth,
          uid: currentCard.uid,
          color: primaryColor,
          profile: currentCard.profile,
          usernamePrefix: isAppAccount ? '@' : '#',
          icon: CupertinoIcons.plus, // Always show + icon for creating new groups
          logo: tokenConfig.logo,
          balance: currentCard.balance,
          onCardBalanceTapped: () => handleBalanceTap(context, myAddress),
          onCardPressed: (uid) => handleCreateNewGroup(context, myAddress),
        ),
      ),
    );
  }

  Future<void> handleBalanceTap(BuildContext context, String myAddress) async {
    // Handle balance tap - could show token selection or balance details
    HapticFeedback.lightImpact();
    // Implementation can be added here if needed
  }

  Future<void> handleGroupTap(String? myAddress, SimpleLendingGroup group) async {
    if (myAddress == null) return;
    
    HapticFeedback.lightImpact();
    
    // Navigate to group details
    final navigator = GoRouter.of(context);
    // TODO: Replace with actual group detail route
    navigator.push('/$myAddress/group/${group.id}');
  }

  Widget _buildGroupListItem(SimpleLendingGroup group, String? myAddress) {
    
    // Get status color
    Color statusColor;
    String statusText;
    switch (group.status) {
      case SimpleGroupStatus.forming:
        statusColor = CupertinoColors.systemOrange;
        statusText = 'Forming';
        break;
      case SimpleGroupStatus.active:
        statusColor = CupertinoColors.systemGreen;
        statusText = 'Active';
        break;
      case SimpleGroupStatus.completed:
        statusColor = CupertinoColors.systemBlue;
        statusText = 'Completed';
        break;
    }
    
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 4),
      onPressed: () => handleGroupTap(myAddress, group),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Group image or placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: group.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.network(
                        group.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          CupertinoIcons.group,
                          color: statusColor,
                          size: 30,
                        ),
                      ),
                    )
                  : Icon(
                      CupertinoIcons.group,
                      color: statusColor,
                      size: 30,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                            Text(
                              '€${group.baseAmount.toStringAsFixed(0)}/month • ${group.members.length}/${group.totalMembers} members',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (group.isActive)
                    const SizedBox(height: 4),
                  if (group.isActive)
                    Text(
                      'Round ${group.currentRound}/${group.totalRounds} • ${group.progressPercentage.toStringAsFixed(0)}% complete',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemGrey,
                ),
                if (group.isActive)
                  const SizedBox(height: 4),
                if (group.isActive)
                  Text(
                    '€${group.totalPoolAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> handleCreateNewGroup(BuildContext context, String myAddress) async {
    HapticFeedback.heavyImpact();
    
    // Show options for testing
    final result = await showCupertinoDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Group Actions'),
        content: const Text('Choose an action for testing:'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop('create'),
            child: const Text('Create New Group'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop('reset'),
            child: const Text('Reset Test Data'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == 'create') {
      // Create a test group
      HapticFeedback.heavyImpact();
      
      _simpleLendingState.addTestGroup();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Created new test group!'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else if (result == 'reset') {
      // Reset test data
      HapticFeedback.heavyImpact();
      _simpleLendingState.resetData();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: const Text('Test data has been reset!'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiredCredentials =
        context.select<WalletState, bool>((state) => state.credentialsExpired);
    if (expiredCredentials) {
      handleExpiredCredentials();
    }

    final safeTopPadding = MediaQuery.of(context).padding.top;


    // Get lending groups from simple state
    final lendingGroups = _simpleLendingState.groups;
    final groupsLoading = _simpleLendingState.loading;
    
    final customContact = context.select(selectCustomContact);
    final customContactProfileByUsername = context
        .select((ContactsState state) => state.customContactProfileByUsername);

    final searching = _searchController.text.isNotEmpty;

    final myAddress =
        context.select((WalletState state) => state.address?.hexEip55);

    final isCard = context.select((CardsState state) =>
        state.cards.firstWhereOrNull((card) => card.account == myAddress) !=
        null);

    final transactionsLoading =
        context.select((TransactionsState state) => state.loading);
    final transactions =
        context.select((TransactionsState state) => state.transactions);
    final orders = context.select((TransactionsState state) => state.orders);
    final profiles =
        context.select((TransactionsState state) => state.profiles);
    final loadingMore =
        context.select((TransactionsState state) => state.loadingMore);

    final config = context.select((WalletState state) => state.config);
    final currentTokenAddress =
        context.select((AppState state) => state.currentTokenAddress);
    final tokenConfig = config.getToken(currentTokenAddress);

    final nothingFound = _searchController.text.isNotEmpty &&
        lendingGroups.isEmpty;

    return AnimatedBuilder(
      animation: _backgroundColorAnimation,
      builder: (context, child) {
        return CupertinoPageScaffold(
          backgroundColor: _backgroundColorAnimation.value,
          child: GestureDetector(
            onTap: _dismissKeyboard,
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    color: _backgroundColorAnimation.value,
                    child: isCard
                        ? CustomScrollView(
                            controller: _cardScrollController,
                            scrollBehavior: const CupertinoScrollBehavior(),
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPersistentHeader(
                                floating: true,
                                delegate: SearchBarDelegate(
                                  safeTopPadding: safeTopPadding,
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onSearch: handleSearch,
                                  onCancel: clearSearch,
                                  isSearching: isSearching,
                                  searching:
                                      searching,
                                  backgroundColor:
                                      _backgroundColorAnimation.value,
                                  isCard: isCard,
                                ),
                              ),
                              CupertinoSliverRefreshControl(
                                onRefresh: handleRefresh,
                              ),
                              if (myAddress != null)
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    childCount: transactions.length,
                                    (context, index) => AnimatedOpacity(
                                      key: Key(
                                        'transaction-list-item-${transactions[index].id}',
                                      ),
                                      opacity: transactionsLoading ? 0.0 : 1.0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: TransactionListItem(
                                        myAddress: myAddress,
                                        transaction: transactions[index],
                                        profiles: profiles,
                                        order:
                                            orders[transactions[index].txHash],
                                        tokenConfig: tokenConfig,
                                        onTap: (transaction, order) =>
                                            handleTransactionTap(
                                          myAddress,
                                          transaction,
                                          order,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (loadingMore)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CupertinoActivityIndicator(),
                                    ),
                                  ),
                                ),
                              if (nothingFound)
                                SliverToBoxAdapter(
                                  child: Center(
                                    child: Text(AppLocalizations.of(context)!
                                        .noResultsFound),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 10,
                                ),
                              ),
                            ],
                          )
                        : CustomScrollView(
                            controller: _scrollController,
                            scrollBehavior: const CupertinoScrollBehavior(),
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPersistentHeader(
                                floating: true,
                                delegate: SearchBarDelegate(
                                  safeTopPadding: safeTopPadding,
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onSearch: handleSearch,
                                  onCancel: clearSearch,
                                  isSearching: isSearching,
                                  searching:
                                      searching,
                                  backgroundColor:
                                      _backgroundColorAnimation.value,
                                  isCard: isCard,
                                ),
                              ),
                              CupertinoSliverRefreshControl(
                                onRefresh: handleRefresh,
                              ),
                              // Add the card at the top of the list
                              SliverToBoxAdapter(
                                child: _buildCardWidget(context, myAddress),
                              ),
                              if (customContact != null)
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    childCount: 1,
                                    (context, index) => ContactListItem(
                                      contact: customContact,
                                      onTap: (contact) => {
                                        // TODO: Handle contact tap
                                      },
                                    ),
                                  ),
                                ),
                              if (customContactProfileByUsername != null)
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    childCount: 1,
                                    (context, index) => ProfileListItem(
                                      profile: customContactProfileByUsername,
                                      onTap: (profile) => {
                                        // TODO: Handle profile tap
                                      },
                                    ),
                                  ),
                                ),
                              // Display lending groups from local database
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  childCount: lendingGroups.length,
                                  (context, index) => _buildGroupListItem(
                                    lendingGroups[index],
                                    myAddress,
                                  ),
                                ),
                              ),
                              if (groupsLoading && lendingGroups.isEmpty)
                                SliverFillRemaining(
                                  child: Center(
                                      child: CupertinoActivityIndicator()),
                                ),
                              if (nothingFound)
                                SliverToBoxAdapter(
                                  child: Center(
                                    child: Text(AppLocalizations.of(context)!
                                        .noResultsFound),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: 10,
                                ),
                              ),
                            ],
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _backgroundColorAnimation.value
                                    ?.withValues(alpha: 0.0) ??
                                whiteColor.withValues(alpha: 0.0),
                            _backgroundColorAnimation.value ?? whiteColor,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double safeTopPadding;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function(String) onSearch;
  final Function() onCancel;
  final bool isSearching;
  final bool searching;
  final Color? backgroundColor;
  final bool isCard;

  SearchBarDelegate({
    required this.safeTopPadding,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.onCancel,
    this.isSearching = false,
    this.searching = false,
    this.backgroundColor,
    this.isCard = false,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            if (!isCard)
              Expanded(
                child: Container(
                  height: 77,
                  width: MediaQuery.of(context).size.width,
                  color: backgroundColor,
                  padding: EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: SearchBar(
                    controller: controller,
                    focusNode: focusNode,
                    onSearch: onSearch,
                    isFocused: isSearching,
                    backgroundColor: backgroundColor,
                  ),
                ),
              ),
            if (isSearching)
              searching
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(18, 0, 44, 0),
                      child: CupertinoActivityIndicator(),
                    )
                  : CupertinoButton(
                      padding: const EdgeInsets.fromLTRB(5, 0, 24, 0),
                      onPressed: onCancel,
                      child: Text(AppLocalizations.of(context)!.cancel),
                    )
          ],
        ),
      ],
    );
  }

  @override
  double get maxExtent =>
      safeTopPadding + 260 + (isCard ? 0 : 77.0); // Height of your SearchBar

  @override
  double get minExtent =>
      safeTopPadding +
      260 +
      (isCard ? 0 : 77.0); // Same as maxExtent for fixed height

  @override
  bool shouldRebuild(covariant SearchBarDelegate oldDelegate) => true;
}
