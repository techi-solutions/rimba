import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WalletKitNotInitializedException implements Exception {
  final String message = 'WalletKit not initialized. Call initWalletConnect() first.';

  WalletKitNotInitializedException();
}

class WalletConnectService {
  ReownWalletKit? _walletKit;
  final Map<String, Completer<SessionData>> _pendingProposals = {};
  final Map<String, Completer<String>> _pendingRequests = {};
  
  final String projectId;
  final PairingMetadata metadata;

  WalletConnectService({
    String? projectId,
    PairingMetadata? metadata,
  })  : projectId = projectId ?? dotenv.env['WALLETCONNECT_PROJECT_ID'] ?? '',
        metadata = metadata ??
            const PairingMetadata(
              name: "Rimba App",
              description: "Flutter app integrating Monerium",
              url: "https://yourapp.com",
              icons: ["https://yourapp.com/icon.png"],
            );

  ReownWalletKit get walletKit {
    if (_walletKit == null) {
      throw WalletKitNotInitializedException();
    }
    return _walletKit!;
  }

  Future<void> init({String? walletAddress}) async {
    try {
      debugPrint('=== WalletConnectService.init() START ===');
      debugPrint('WalletConnectService.init() - Project ID: ${projectId.isEmpty ? "(not set)" : "***"}');
      
      if (projectId.isEmpty) {
        throw Exception('WalletConnect Project ID not configured. Set WALLETCONNECT_PROJECT_ID in .env');
      }

      _walletKit = await ReownWalletKit.createInstance(
        projectId: projectId,
        metadata: metadata,
      );
      debugPrint('WalletConnectService.init() - ReownWalletKit instance created');

      // Register account if provided
      if (walletAddress != null) {
        debugPrint('WalletConnectService.init() - Registering wallet address: ${walletAddress.substring(0, 8)}...');
        walletKit.registerAccount(
          chainId: 'eip155:1',
          accountAddress: walletAddress,
        );
      }

      // Set up listeners for session proposals
      walletKit.onSessionProposal.subscribe(_onSessionProposal);
      debugPrint('WalletConnectService.init() - Session proposal listener registered');
      
      // Set up listeners for session requests (signing, transactions, etc.)
      walletKit.onSessionRequest.subscribe(_onSessionRequest);
      debugPrint('WalletConnectService.init() - Session request listener registered');
      
      // Register handler for personal_sign
      walletKit.registerRequestHandler(
        chainId: 'eip155:1',
        method: 'personal_sign',
      );
      
      // Register handler for eth_sendTransaction
      walletKit.registerRequestHandler(
        chainId: 'eip155:1',
        method: 'eth_sendTransaction',
      );
      debugPrint('WalletConnectService.init() - Request handlers registered');
      
      debugPrint('=== WalletConnectService.init() END ===');
    } catch (e, s) {
      debugPrint('WalletConnectService.init() - ERROR: $e');
      debugPrint('WalletConnectService.init() - Stack trace: $s');
      rethrow;
    }
  }

  /// Handle incoming session proposals from dapps
  void _onSessionProposal(SessionProposalEvent? event) {
    if (event != null) {
      debugPrint('WalletConnectService._onSessionProposal() - Received proposal from: ${event.params.proposer.metadata.name}');
      debugPrint('WalletConnectService._onSessionProposal() - Proposer URL: ${event.params.proposer.metadata.url}');
      // You can auto-approve or show UI to user for approval
    }
  }

  /// Handle incoming session requests (sign message, send transaction, etc.)
  void _onSessionRequest(SessionRequestEvent? event) async {
    if (event != null) {
      debugPrint('WalletConnectService._onSessionRequest() - Received request: ${event.method}');
      debugPrint('WalletConnectService._onSessionRequest() - Topic: ${event.topic}');
      final requestId = event.id.toString();
      
      // Notify any pending request handlers
      if (_pendingRequests.containsKey(requestId)) {
        debugPrint('WalletConnectService._onSessionRequest() - Found pending request handler for ID: $requestId');
        // Handle the request completion
        // You'll need to implement actual signing logic here
      }
    }
  }

  /// Pair with a dapp using a WalletConnect URI
  /// (typically from scanning a QR code)
  Future<PairingInfo> pairWithDapp(String uri) async {
    try {
      debugPrint('WalletConnectService.pairWithDapp() - Pairing with URI: ${uri.substring(0, 20)}...');
      final result = await walletKit.pair(uri: Uri.parse(uri));
      debugPrint('WalletConnectService.pairWithDapp() - Pairing successful');
      return result;
    } catch (e, s) {
      debugPrint('WalletConnectService.pairWithDapp() - ERROR: $e');
      debugPrint('WalletConnectService.pairWithDapp() - Stack trace: $s');
      rethrow;
    }
  }

  /// Approve a session proposal
  Future<SessionData> approveSession({
    required int proposalId,
    required Map<String, Namespace> namespaces,
  }) async {
    try {
      debugPrint('WalletConnectService.approveSession() - Approving proposal ID: $proposalId');
      final response = await walletKit.approveSession(
        id: proposalId,
        namespaces: namespaces,
      );
      debugPrint('WalletConnectService.approveSession() - Session approved, topic: ${response.topic}');
      
      return walletKit.sessions.get(response.topic)!;
    } catch (e, s) {
      debugPrint('WalletConnectService.approveSession() - ERROR: $e');
      debugPrint('WalletConnectService.approveSession() - Stack trace: $s');
      rethrow;
    }
  }

  /// Reject a session proposal
  Future<void> rejectSession(int proposalId) async {
    try {
      debugPrint('WalletConnectService.rejectSession() - Rejecting proposal ID: $proposalId');
      await walletKit.rejectSession(
        id: proposalId,
        reason: ReownSignError(
          code: 5000,
          message: 'User rejected',
        ),
      );
      debugPrint('WalletConnectService.rejectSession() - Session rejected');
    } catch (e, s) {
      debugPrint('WalletConnectService.rejectSession() - ERROR: $e');
      debugPrint('WalletConnectService.rejectSession() - Stack trace: $s');
      rethrow;
    }
  }

  /// Get all active sessions
  List<SessionData> getActiveSessions() {
    return walletKit.sessions.getAll();
  }

  /// Extract the connected Ethereum address from the session
  String? getConnectedAddress(SessionData session) {
    final accounts = session.namespaces['eip155']?.accounts;
    if (accounts != null && accounts.isNotEmpty) {
      return accounts.first.split(':').last;
    }
    return null;
  }

  /// Respond to a signing request
  /// Note: You need to implement actual signing logic with your wallet's private key
  Future<void> approveRequest({
    required String topic,
    required int requestId,
    required String result,
  }) async {
    try {
      debugPrint('WalletConnectService.approveRequest() - Approving request ID: $requestId');
      await walletKit.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: '2.0',
          result: result,
        ),
      );
      debugPrint('WalletConnectService.approveRequest() - Request approved');
    } catch (e, s) {
      debugPrint('WalletConnectService.approveRequest() - ERROR: $e');
      debugPrint('WalletConnectService.approveRequest() - Stack trace: $s');
      rethrow;
    }
  }

  /// Reject a signing request
  Future<void> rejectRequest({
    required String topic,
    required int requestId,
    required String error,
  }) async {
    try {
      debugPrint('WalletConnectService.rejectRequest() - Rejecting request ID: $requestId');
      await walletKit.respondSessionRequest(
        topic: topic,
        response: JsonRpcResponse(
          id: requestId,
          jsonrpc: '2.0',
          error: JsonRpcError(
            code: 5000,
            message: error,
          ),
        ),
      );
      debugPrint('WalletConnectService.rejectRequest() - Request rejected');
    } catch (e, s) {
      debugPrint('WalletConnectService.rejectRequest() - ERROR: $e');
      debugPrint('WalletConnectService.rejectRequest() - Stack trace: $s');
      rethrow;
    }
  }

  /// Disconnect a session
  Future<void> disconnectSession(String topic) async {
    try {
      debugPrint('WalletConnectService.disconnectSession() - Disconnecting topic: ${topic.substring(0, 8)}...');
      await walletKit.disconnectSession(
        topic: topic,
        reason: ReownSignError(
          code: 6000,
          message: 'User disconnected',
        ),
      );
      debugPrint('WalletConnectService.disconnectSession() - Session disconnected');
    } catch (e, s) {
      debugPrint('WalletConnectService.disconnectSession() - ERROR: $e');
      debugPrint('WalletConnectService.disconnectSession() - Stack trace: $s');
      rethrow;
    }
  }

  /// Clean up resources
  void dispose() {
    debugPrint('WalletConnectService.dispose() - Cleaning up resources');
    if (_walletKit != null) {
      walletKit.onSessionProposal.unsubscribe(_onSessionProposal);
      walletKit.onSessionRequest.unsubscribe(_onSessionRequest);
    }
    _pendingProposals.clear();
    _pendingRequests.clear();
  }
}

