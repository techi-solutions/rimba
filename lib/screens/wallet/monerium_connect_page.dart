import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:web3dart/crypto.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/services/monerium/monerium_auth_service.dart';
import 'package:pay_app/services/secure/secure.dart';
import 'package:pay_app/state/profile.dart';

class MoneriumConnectPage extends StatefulWidget {
  const MoneriumConnectPage({super.key});

  @override
  State<MoneriumConnectPage> createState() => _MoneriumConnectPageState();
}

class _MoneriumConnectPageState extends State<MoneriumConnectPage> {
  final MoneriumAuthService _authService = MoneriumAuthService();
  final SecureService _secureService = SecureService();
  final AppLinks _appLinks = AppLinks();

  String? statusMessage;
  bool isLoading = false;
  bool isConnected = false;
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _checkIfConnected();
  }

  /// Check if already connected to Monerium
  void _checkIfConnected() {
    if (_authService.accessToken != null) {
      setState(() {
        isConnected = true;
        statusMessage = 'Already connected to Monerium';
      });
      _fetchProfile();
    }
  }

  /// Handle OAuth callback from Monerium
  void _handleIncomingLinks() {
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });

    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Error handling deep link: $err');
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.queryParameters.containsKey('code')) {
      setState(() => isLoading = true);

      try {
        final code = uri.queryParameters['code']!;

        await _authService.exchangeCodeForToken(code);

        if (mounted) {
          setState(() {
            isConnected = true;
            statusMessage = 'Successfully connected to Monerium!';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Connected to Monerium!"),
              backgroundColor: Colors.green,
            ),
          );

          await _fetchProfile();
        }
      } catch (e, s) {
        if (mounted) {
          setState(() => statusMessage = 'Failed to connect: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to connect: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  /// Fetch user profile from Monerium
  Future<void> _fetchProfile() async {
    try {
      final profile = await _authService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          userProfile = profile;
          statusMessage = 'Profile loaded: ${profile['email'] ?? 'Unknown'}';
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  /// Main flow: Connect wallet to Monerium
  Future<void> _connectToMonerium() async {
    setState(() {
      isLoading = true;
      statusMessage = 'Getting wallet address...';
    });

    try {
      // Get wallet address from your existing wallet
      final profileState = context.read<ProfileState>();
      final address = profileState.appAccount;

      if (address.hexEip55.isEmpty) {
        throw Exception(
            'No wallet found. Please create or import a wallet first.');
      }

      setState(() => statusMessage = 'Signing message...');

      // Sign message to prove wallet ownership
      final message = "Link this wallet to Monerium";
      final signature = await _signMessage(message);

      setState(() => statusMessage = 'Launching Monerium authorization...');

      // Generate PKCE for OAuth
      final pkce = await _authService.generatePKCE();

      // Build OAuth URL with wallet signature
      final authUrl = await _authService.buildAuthUrl(
        pkce['challenge']!,
        address: address.hexEip55,
        signature: signature,
        chain: 'eip155:1', // Ethereum mainnet
      );

      // Launch browser for OAuth
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        setState(() => statusMessage = 'Complete authorization in browser...');
      } else {
        throw Exception('Could not launch browser');
      }
    } catch (e, s) {
      debugPrint('MoneriumConnectPage._connectToMonerium() - ERROR: $e');
      debugPrint('MoneriumConnectPage._connectToMonerium() - Stack trace: $s');

      if (mounted) {
        setState(() => statusMessage = 'Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Sign message with stored private key
  Future<String> _signMessage(String message) async {
    try {
      final credentials = _secureService.getCredentials();
      if (credentials == null) {
        throw Exception('No wallet credentials found');
      }

      final (_, privateKey) = credentials;
      final messageBytes = utf8.encode(message);
      final signature = await privateKey.signPersonalMessage(messageBytes);
      return bytesToHex(signature, include0x: true);
    } catch (e, s) {
      debugPrint('_signMessage() - ERROR: $e');
      debugPrint('_signMessage() - Stack trace: $s');
      rethrow;
    }
  }

  /// Disconnect from Monerium
  void _disconnect() {
    setState(() {
      _authService.clearAuth();
      isConnected = false;
      userProfile = null;
      statusMessage = 'Disconnected from Monerium';
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileState>();
    final address = profileState.appAccount;
    final hasWallet = address.hexEip55.isNotEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Icon
                  Center(
                    child: Column(
                      children: [
                        if (isLoading)
                          const CupertinoActivityIndicator(radius: 20)
                        else if (isConnected)
                          const Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.systemGreen,
                            size: 80,
                          )
                        else
                          const Icon(
                            CupertinoIcons.money_dollar_circle_fill,
                            size: 80,
                            color: CupertinoColors.activeBlue,
                          ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          isConnected ? 'Connected' : 'Connect Your Wallet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),

                        // Wallet Address
                        if (hasWallet)
                          Text(
                            address.hexEip55,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Status Message
                  if (statusMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Profile Info
                  if (userProfile != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monerium Profile',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (userProfile!['email'] != null)
                              Text('Email: ${userProfile!['email']}'),
                            if (userProfile!['name'] != null)
                              Text('Name: ${userProfile!['name']}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!hasWallet)
                    CupertinoButton(
                      onPressed: null,
                      color: CupertinoColors.systemGrey,
                      child: const Text('No Wallet Found'),
                    )
                  else if (isConnected)
                    CupertinoButton(
                      onPressed: isLoading ? null : _disconnect,
                      color: CupertinoColors.systemRed,
                      child: const Text('Disconnect'),
                    )
                  else
                    CupertinoButton(
                      onPressed: isLoading ? null : _connectToMonerium,
                      color: CupertinoColors.activeBlue,
                      child: const Text(
                        'Connect to Monerium',
                        style: TextStyle(color: CupertinoColors.white),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Info Text
                  if (!isConnected)
                    const Text(
                      'Link your wallet to Monerium to enable fiat transfers and SEPA payments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the Monerium connect modal
void showMoneriumConnectModal(BuildContext context) {
  final profileState = context.read<ProfileState>();

  showCupertinoModalPopup(
    context: context,
    useRootNavigator: false,
    builder: (BuildContext modalContext) {
      return ChangeNotifierProvider<ProfileState>.value(
        value: profileState,
        child: const MoneriumConnectPage(),
      );
    },
  );
}
