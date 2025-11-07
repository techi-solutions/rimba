import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:web3dart/crypto.dart';
import 'package:pay_app/services/wallet/wallet_service.dart';
import 'package:pay_app/services/monerium/monerium_auth_service.dart';
import 'package:pay_app/services/secure/secure.dart';

class ConnectWalletPage extends StatefulWidget {
  const ConnectWalletPage({super.key});

  @override
  State<ConnectWalletPage> createState() => _ConnectWalletPageState();
}

class _ConnectWalletPageState extends State<ConnectWalletPage> {
  final WalletConnectService _walletService = WalletConnectService();
  final MoneriumAuthService _authService = MoneriumAuthService();
  final SecureService _secureService = SecureService();
  final AppLinks _appLinks = AppLinks();
  final TextEditingController _qrController = TextEditingController();
  
  SessionData? currentSession;
  String? statusMessage;
  String? walletAddress;
  bool isLoading = false;
  List<SessionData> activeSessions = [];

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    try {
      debugPrint('=== ConnectWalletPage._initServices() START ===');
      // Initialize wallet service
      // In a real app, you'd get the wallet address from your existing wallet service
      await _walletService.init(
        walletAddress: walletAddress,
      );
      debugPrint('ConnectWalletPage._initServices() - WalletConnect initialized');
      
      // Set up session proposal listener
      _walletService.walletKit.onSessionProposal.subscribe(_onSessionProposal);
      
      // Set up session request listener
      _walletService.walletKit.onSessionRequest.subscribe(_onSessionRequest);
      
      _handleIncomingLinks();
      _updateStatus('WalletConnect initialized. Ready to connect.');
      debugPrint('=== ConnectWalletPage._initServices() END ===');
    } catch (e, s) {
      debugPrint('ConnectWalletPage._initServices() - ERROR: $e');
      debugPrint('ConnectWalletPage._initServices() - Stack trace: $s');
      _updateStatus('Error initializing: $e');
    }
  }

  /// Handle incoming session proposals from dapps
  void _onSessionProposal(SessionProposalEvent? event) async {
    if (event == null) return;
    
    setState(() => statusMessage = 'Received connection request from ${event.params.proposer.metadata.name}');
    
    // Show dialog to user for approval
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${event.params.proposer.metadata.name}'),
            Text('URL: ${event.params.proposer.metadata.url}'),
            Text('\n${event.params.proposer.metadata.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    
    if (approved == true && walletAddress != null) {
      try {
        // Approve the session
        final session = await _walletService.approveSession(
          proposalId: event.id,
          namespaces: {
            'eip155': Namespace(
              accounts: ['eip155:1:$walletAddress'],
              methods: ['personal_sign', 'eth_sendTransaction'],
              events: ['chainChanged', 'accountsChanged'],
            ),
          },
        );
        
        setState(() {
          currentSession = session;
          activeSessions = _walletService.getActiveSessions();
        });
        
        _updateStatus('Connected to ${event.params.proposer.metadata.name}!');
        
        // Now you can proceed with Monerium authorization
        if (walletAddress != null) {
          await startMoneriumAuth(walletAddress!);
        }
      } catch (e, s) {
        debugPrint('ConnectWalletPage._onSessionProposal() - ERROR: $e');
        debugPrint('ConnectWalletPage._onSessionProposal() - Stack trace: $s');
        _updateStatus('Error approving session: $e');
      }
    } else {
      await _walletService.rejectSession(event.id);
      _updateStatus('Connection rejected');
    }
  }

  /// Handle incoming session requests (signing, transactions, etc.)
  void _onSessionRequest(SessionRequestEvent? event) async {
    if (event == null) return;
    
    setState(() => statusMessage = 'Received signing request: ${event.method}');
    
    // Show dialog for signing approval
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signature Request'),
        content: Text('Method: ${event.method}\n\nApprove this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign'),
          ),
        ],
      ),
    );
    
    if (approved == true) {
      try {
        // Here you would implement actual signing logic
        // For now, we'll just show that it needs to be implemented
        final signature = await _signMessageWithPrivateKey(
          event.params as List<dynamic>,
        );
        
        await _walletService.approveRequest(
          topic: event.topic,
          requestId: event.id,
          result: signature,
        );
        
        _updateStatus('Request signed successfully');
      } catch (e, s) {
        debugPrint('ConnectWalletPage._onSessionRequest() - ERROR: $e');
        debugPrint('ConnectWalletPage._onSessionRequest() - Stack trace: $s');
        await _walletService.rejectRequest(
          topic: event.topic,
          requestId: event.id,
          error: e.toString(),
        );
        _updateStatus('Error signing request: $e');
      }
    } else {
      await _walletService.rejectRequest(
        topic: event.topic,
        requestId: event.id,
        error: 'User rejected',
      );
    }
  }

  /// Sign message with the app's stored private key
  Future<String> _signMessageWithPrivateKey(List<dynamic> params) async {
    try {
      debugPrint('_signMessageWithPrivateKey() - START');
      
      // Get credentials from secure storage
      final credentials = _secureService.getCredentials();
      if (credentials == null) {
        throw Exception('No wallet credentials found. Please ensure you are logged in.');
      }
      
      final (account, privateKey) = credentials;
      debugPrint('_signMessageWithPrivateKey() - Signing with account: ${account.hexEip55}');
      
      // Parse the message to sign
      final message = params[0] as String;
      debugPrint('_signMessageWithPrivateKey() - Message: $message');
      
      // Sign the message using personal_sign format
      final messageBytes = utf8.encode(message);
      final signature = await privateKey.signPersonalMessage(messageBytes);
      final signatureHex = bytesToHex(signature, include0x: true);
      
      debugPrint('_signMessageWithPrivateKey() - Signature created: ${signatureHex.substring(0, 10)}...');
      return signatureHex;
    } catch (e, s) {
      debugPrint('_signMessageWithPrivateKey() - ERROR: $e');
      debugPrint('_signMessageWithPrivateKey() - Stack trace: $s');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  void _handleIncomingLinks() {
    // Handle the initial link if the app is started via a deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Handle incoming links while the app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      _updateStatus('Error handling deep link: $err');
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    // Handle WalletConnect URI
    if (uri.scheme == 'wc' || uri.toString().contains('wc?uri=')) {
      await _pairWithUri(uri.toString());
      return;
    }
    
    // Handle Monerium OAuth callback
    if (uri.queryParameters.containsKey('code')) {
      setState(() => isLoading = true);
      
      try {
        final code = uri.queryParameters['code']!;
        await _authService.exchangeCodeForToken(code);
        
        if (mounted) {
          _updateStatus('Successfully connected to Monerium!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Connected to Monerium!"),
              backgroundColor: Colors.green,
            ),
          );
          
          // Optionally fetch and display user profile
          final profile = await _authService.getProfile();
          if (profile != null && mounted) {
            _updateStatus('Profile loaded: ${profile['email'] ?? 'Unknown'}');
          }
        }
      } catch (e, s) {
        debugPrint('ConnectWalletPage._handleDeepLink() - ERROR: $e');
        debugPrint('ConnectWalletPage._handleDeepLink() - Stack trace: $s');
        if (mounted) {
          _updateStatus('Error: $e');
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

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => statusMessage = message);
    }
  }

  Future<void> _pairWithUri(String uri) async {
    setState(() {
      isLoading = true;
      statusMessage = 'Pairing with dapp...';
    });

    try {
      await _walletService.pairWithDapp(uri);
      _updateStatus('Pairing successful. Waiting for session proposal...');
    } catch (e, s) {
      debugPrint('ConnectWalletPage._pairWithUri() - ERROR: $e');
      debugPrint('ConnectWalletPage._pairWithUri() - Stack trace: $s');
      _updateStatus('Error pairing: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showPairDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pair with Dapp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter WalletConnect URI or scan QR code:'),
            const SizedBox(height: 16),
            TextField(
              controller: _qrController,
              decoration: const InputDecoration(
                hintText: 'wc:...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_qrController.text.isNotEmpty) {
                _pairWithUri(_qrController.text);
              }
            },
            child: const Text('Pair'),
          ),
        ],
      ),
    );
  }

  Future<void> startMoneriumAuth(String address) async {
    try {
      debugPrint('ConnectWalletPage.startMoneriumAuth() - Starting Monerium auth for address: ${address.substring(0, 8)}...');
      
      // Sign the Monerium authorization message
      _updateStatus('Signing message for Monerium...');
      final message = "Link this wallet to Monerium";
      final signature = await _signMoneriumMessage(message);
      debugPrint('ConnectWalletPage.startMoneriumAuth() - Message signed');
      
      // Generate PKCE for OAuth
      final pkce = await _authService.generatePKCE();
      
      // Build auth URL with real signature
      final baseAuthUrl = await _authService.buildAuthUrl(
        pkce['challenge']!,
        address: address,
        signature: signature, // Real signature, not placeholder!
        chain: 'eip155:1',
      );

      final uri = Uri.parse(baseAuthUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        _updateStatus('Launched Monerium authorization...');
        debugPrint('ConnectWalletPage.startMoneriumAuth() - Monerium auth URL launched');
      } else {
        throw Exception('Could not launch auth URL');
      }
    } catch (e, s) {
      debugPrint('ConnectWalletPage.startMoneriumAuth() - ERROR: $e');
      debugPrint('ConnectWalletPage.startMoneriumAuth() - Stack trace: $s');
      _updateStatus('Error launching auth: $e');
      rethrow;
    }
  }

  /// Sign a message for Monerium authorization
  Future<String> _signMoneriumMessage(String message) async {
    try {
      debugPrint('_signMoneriumMessage() - Signing message: $message');
      
      final credentials = _secureService.getCredentials();
      if (credentials == null) {
        throw Exception('No wallet credentials found');
      }
      
      final (_, privateKey) = credentials;
      final messageBytes = utf8.encode(message);
      final signature = await privateKey.signPersonalMessage(messageBytes);
      final signatureHex = bytesToHex(signature, include0x: true);
      
      debugPrint('_signMoneriumMessage() - Signature: ${signatureHex.substring(0, 10)}...');
      return signatureHex;
    } catch (e, s) {
      debugPrint('_signMoneriumMessage() - ERROR: $e');
      debugPrint('_signMoneriumMessage() - Stack trace: $s');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WalletConnect + Monerium"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet address input
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Your Wallet Address',
                  border: OutlineInputBorder(),
                  hintText: '0x...',
                ),
                onChanged: (value) {
                  setState(() => walletAddress = value);
                },
              ),
              
              const SizedBox(height: 24),
              
              // Status indicator
              Center(
                child: Column(
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator()
                    else if (currentSession != null)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 64,
                      )
                    else
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 64,
                        color: Colors.blue,
                      ),
                    const SizedBox(height: 16),
                    if (statusMessage != null)
                      Text(
                        statusMessage!,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Pair button
              ElevatedButton.icon(
                onPressed: walletAddress != null && !isLoading 
                    ? _showPairDialog
                    : null,
                icon: const Icon(Icons.qr_code),
                label: const Text("Pair with Dapp"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Active sessions
              if (activeSessions.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Active Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...activeSessions.map((session) {
                  final peer = session.peer.metadata;
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(peer.name),
                      subtitle: Text(peer.url),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () async {
                          await _walletService.disconnectSession(session.topic);
                          setState(() {
                            activeSessions = _walletService.getActiveSessions();
                          });
                        },
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('ConnectWalletPage.dispose() - Cleaning up');
    _walletService.dispose();
    _qrController.dispose();
    super.dispose();
  }
}

