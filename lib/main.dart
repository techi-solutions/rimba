import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_app/routes/router.dart';
import 'package:pay_app/services/audio/audio.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/services/config/service.dart';
import 'package:pay_app/services/db/app/db.dart';
import 'package:pay_app/services/preferences/preferences.dart';
import 'package:pay_app/services/secure/secure.dart';
import 'package:pay_app/services/localization/localization_service.dart';
import 'package:pay_app/state/app.dart';
import 'package:pay_app/state/onboarding.dart';
import 'package:pay_app/state/state.dart';
import 'package:pay_app/state/locale_state.dart';
import 'package:pay_app/widgets/offline_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pay_app/l10n/app_localizations.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crashlytics setup
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize local services
  await AppDBService().openDB('main');
  await PreferencesService().init(await SharedPreferences.getInstance());
  await SecureService().init(await SharedPreferences.getInstance());

  final audioService = AudioService();
  final audioMuted = PreferencesService().audioMuted;
  await audioService.init(muted: audioMuted);

  final ConfigService configService = ConfigService();
  final config = await configService.getLocalConfig();
  if (config == null) {
    throw Exception('Community not found in local asset');
  }
  await config.initContracts();

  runApp(provideAppState(config, MyApp(config: config)));
}

class MyApp extends StatefulWidget {
  final Config config;
  const MyApp({super.key, required this.config});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _appShellNavigatorKey = GlobalKey<NavigatorState>();
  final _placeShellNavigatorKey = GlobalKey<NavigatorState>();
  final observers = <NavigatorObserver>[];
  late GoRouter router;

  late OnboardingState _onboardingState;
  late AppLinks _appLinks;
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();

    _onboardingState = context.read<OnboardingState>();
    final accountAddress = _onboardingState.getAccountAddress();

    router = createRouter(
      _rootNavigatorKey,
      _appShellNavigatorKey,
      _placeShellNavigatorKey,
      observers,
      config: widget.config,
      accountAddress: accountAddress,
    );

    _initDeepLinkHandling();
  }

  void _initDeepLinkHandling() async {
    _appLinks = AppLinks();
    
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }

      _linkSub = _appLinks.uriLinkStream.listen(
        (Uri uri) => _handleIncomingUri(uri),
        onError: (err) => debugPrint('Deep link error: $err'),
      );
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }
  }

  void _handleIncomingUri(Uri uri) {
    debugPrint('Deep link received: $uri');
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        router.go('/');
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.select<AppState, CupertinoThemeData>(
      (state) => CupertinoThemeData(
        primaryColor: state.tokenPrimaryColor,
        brightness: Brightness.light,
        scaffoldBackgroundColor: CupertinoColors.systemBackground,
        textTheme: const CupertinoTextThemeData(
          textStyle: TextStyle(
            color: CupertinoColors.label,
            fontSize: 16,
          ),
        ),
        applyThemeToAll: true,
      ),
    );

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: theme,
      title: AppLocalizations.of(context)?.appTitle ?? 'Brussels Pay',
      locale: context
              .select<LocaleState, Locale?>((state) => state.currentLocale) ??
          LocalizationService.defaultLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.0)),
        child: CupertinoPageScaffold(
          key: const Key('main'),
          backgroundColor: theme.scaffoldBackgroundColor,
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: child != null
                    ? CupertinoTheme(
                        data: theme,
                        child: child,
                      )
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
