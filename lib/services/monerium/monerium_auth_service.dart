import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'package:pay_app/services/api/api.dart';

class MoneriumAuthService {
  final APIService _apiService;
  final String clientId;
  final String clientSecret;
  final String redirectUri;

  String? _codeVerifier;
  String? _accessToken;

  String? get accessToken => _accessToken;

  MoneriumAuthService({
    String? baseUrl,
    String? clientId,
    String? clientSecret,
    String? redirectUri,
  })  : clientId = clientId ?? dotenv.env['MONERIUM_CLIENT_ID'] ?? '',
        clientSecret = clientSecret ?? dotenv.env['MONERIUM_CLIENT_SECRET'] ?? '',
        redirectUri = redirectUri ?? dotenv.env['MONERIUM_REDIRECT_URI'] ?? 'rimba://monerium',
        _apiService = APIService(
          baseURL: baseUrl ?? dotenv.env['MONERIUM_BASE_URL'] ?? 'https://api.monerium.dev',
        );

  /// Generate PKCE code verifier and challenge
  Future<Map<String, String>> generatePKCE() async {
    try {
      debugPrint('MoneriumAuthService.generatePKCE() - Generating PKCE');
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      _codeVerifier = base64UrlEncode(values).replaceAll('=', '');
      
      final bytes = utf8.encode(_codeVerifier!);
      final digest = sha256.convert(bytes);
      final challenge = base64UrlEncode(digest.bytes).replaceAll('=', '');
      
      debugPrint('MoneriumAuthService.generatePKCE() - PKCE generated successfully');
      return {
        'verifier': _codeVerifier!,
        'challenge': challenge,
      };
    } catch (e, s) {
      debugPrint('MoneriumAuthService.generatePKCE() - ERROR: $e');
      debugPrint('MoneriumAuthService.generatePKCE() - Stack trace: $s');
      rethrow;
    }
  }

  /// Build the Monerium OAuth authorization URL
  Future<String> buildAuthUrl(String challenge, {String? address, String? signature, String? chain}) async {
    try {
      debugPrint('MoneriumAuthService.buildAuthUrl() - Building auth URL');
      
      if (clientId.isEmpty) {
        throw Exception('Monerium Client ID not configured. Set MONERIUM_CLIENT_ID in .env');
      }
      
      var url = "${_apiService.baseURL}/auth?"
          "client_id=$clientId"
          "&redirect_uri=$redirectUri"
          "&response_type=code"
          "&code_challenge=$challenge"
          "&code_challenge_method=S256";
      
      if (address != null && signature != null && chain != null) {
        debugPrint('MoneriumAuthService.buildAuthUrl() - Adding wallet parameters');
        url += "&address=$address&signature=$signature&chain=$chain";
      }
      
      debugPrint('MoneriumAuthService.buildAuthUrl() - Auth URL built successfully');
      return url;
    } catch (e, s) {
      debugPrint('MoneriumAuthService.buildAuthUrl() - ERROR: $e');
      debugPrint('MoneriumAuthService.buildAuthUrl() - Stack trace: $s');
      rethrow;
    }
  }

  /// Exchange authorization code for access token
  Future<void> exchangeCodeForToken(String code) async {
    try {
      debugPrint('MoneriumAuthService.exchangeCodeForToken() - Exchanging code for token');
      
      if (_codeVerifier == null) {
        throw Exception("PKCE verifier not found. Call generatePKCE() first.");
      }

      if (clientId.isEmpty || clientSecret.isEmpty) {
        throw Exception('Monerium credentials not configured. Set MONERIUM_CLIENT_ID and MONERIUM_CLIENT_SECRET in .env');
      }

      final body = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': clientSecret,
        'code_verifier': _codeVerifier!,
      };

      final data = await _apiService.post(
        url: '/auth/token',
        body: body,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      _accessToken = data['access_token'];
      debugPrint('MoneriumAuthService.exchangeCodeForToken() - Token obtained successfully');
      
      // Optionally store refresh token and expiry
      // final refreshToken = data['refresh_token'];
      // final expiresIn = data['expires_in'];
    } catch (e, s) {
      debugPrint('MoneriumAuthService.exchangeCodeForToken() - ERROR: $e');
      debugPrint('MoneriumAuthService.exchangeCodeForToken() - Stack trace: $s');
      rethrow;
    }
  }

  /// Make authenticated requests to Monerium API
  Future<dynamic> makeAuthenticatedRequest(String endpoint, {String method = 'GET', Map<String, dynamic>? body}) async {
    try {
      debugPrint('MoneriumAuthService.makeAuthenticatedRequest() - $method $endpoint');
      
      if (_accessToken == null) {
        throw UnauthorizedException();
      }

      final headers = {
        'Authorization': 'Bearer $_accessToken',
      };

      switch (method.toUpperCase()) {
        case 'POST':
          return await _apiService.post(url: endpoint, body: body!, headers: headers);
        case 'PUT':
          return await _apiService.put(url: endpoint, body: body!, headers: headers);
        case 'DELETE':
          return await _apiService.delete(url: endpoint, body: body ?? {}, headers: headers);
        default:
          return await _apiService.get(url: endpoint, headers: headers);
      }
    } catch (e, s) {
      debugPrint('MoneriumAuthService.makeAuthenticatedRequest() - ERROR: $e');
      debugPrint('MoneriumAuthService.makeAuthenticatedRequest() - Stack trace: $s');
      rethrow;
    }
  }

  /// Get user profile from Monerium
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      debugPrint('MoneriumAuthService.getProfile() - Fetching profile');
      final response = await makeAuthenticatedRequest('/profiles');
      debugPrint('MoneriumAuthService.getProfile() - Profile fetched');
      return response;
    } catch (e, s) {
      debugPrint('MoneriumAuthService.getProfile() - ERROR: $e');
      debugPrint('MoneriumAuthService.getProfile() - Stack trace: $s');
      return null;
    }
  }

  /// Get linked wallets
  Future<List<dynamic>?> getWallets() async {
    try {
      debugPrint('MoneriumAuthService.getWallets() - Fetching wallets');
      final response = await makeAuthenticatedRequest('/wallets');
      debugPrint('MoneriumAuthService.getWallets() - Wallets fetched');
      return response;
    } catch (e, s) {
      debugPrint('MoneriumAuthService.getWallets() - ERROR: $e');
      debugPrint('MoneriumAuthService.getWallets() - Stack trace: $s');
      return null;
    }
  }

  /// Clear authentication state
  void clearAuth() {
    debugPrint('MoneriumAuthService.clearAuth() - Clearing authentication state');
    _accessToken = null;
    _codeVerifier = null;
  }
}

