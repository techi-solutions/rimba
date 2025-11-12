import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

class MoneriumAuthService {
  static const String _baseUrl = 'https://api.monerium.app';
  static const String _authPath = '/auth';
  static const String _tokenPath = '/auth/token';

  /// Generates a high-entropy random string for PKCE code verifier
  ///
  /// Per RFC 7636 Section 4.1:
  /// - Must be a random, high-entropy string between 43 and 128 characters
  /// - Uses unreserved characters: [A-Z] / [a-z] / [0-9] / "-" / "." / "_" / "~"
  ///
  /// Returns a base64url-encoded string (86 characters for 64 bytes of entropy)
  String generateCodeVerifier() {
    final Random random = Random.secure();
    // Generate 64 random bytes (512 bits of entropy)
    // Base64url encoding of 64 bytes produces 86 characters (within 43-128 range)
    final List<int> values = List<int>.generate(64, (i) => random.nextInt(256));
    // Base64url encode and remove padding (if any)
    return base64UrlEncode(values).replaceAll('=', '');
  }

  /// Generates code challenge from code verifier using SHA-256 and base64 URL encoding
  ///
  /// Per RFC 7636 Section 4.2:
  /// code_challenge = base64urlEncode(SHA256(ASCII(code_verifier)))
  ///
  /// [codeVerifier] - The code verifier string
  /// Returns the base64url-encoded SHA-256 hash of the code verifier
  String generateCodeChallenge(String codeVerifier) {
    // Convert code verifier to ASCII bytes (RFC 7636 specifies ASCII encoding)
    final List<int> bytes = utf8.encode(codeVerifier);
    // Compute SHA-256 hash
    final Digest digest = sha256.convert(bytes);
    // Base64url encode the hash and remove padding
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Signs the Monerium ownership declaration message
  ///
  /// Signs the message with the provided private key and returns the signature
  /// in the format expected by Safe's checkSignatures function.
  ///
  /// The signature is a standard ECDSA signature (65 bytes: r | s | v) that
  /// can be validated by the Safe contract's isValidSignature method.
  ///
  /// For Safe wallets: Uses personal sign on the message hash and adjusts v
  /// for eth_sign flow (v > 30) so Safe's checkSignatures can handle it.
  ///
  /// [privateKey] - The Ethereum private key to sign with
  /// [message] - The message hash to sign (should be the Safe message hash)
  /// [chainId] - The chain ID (defaults to 100 for Gnosis)
  ///
  /// Returns a Uint8List of 65 bytes (r | s | v) where v = 31 or 32 for eth_sign flow
  Uint8List signOwnershipMessage({
    required EthPrivateKey privateKey,
    bool isSafe = false,
    Uint8List? message,
    int chainId = 100,
  }) {
    final defaultMessage =
        utf8.encode('I hereby declare that I am the address owner.');

    final messageBytes = message ?? defaultMessage;

    // Sign the message hash with personal sign
    var signature = privateKey.signPersonalMessageToUint8List(messageBytes);

    // Verify the signature is exactly 65 bytes
    if (signature.length != 65) {
      throw Exception(
          'Invalid signature length: expected 65 bytes, got ${signature.length}');
    }

    final offset = isSafe ? 4 : 0;

    // Adjust v for eth_sign flow (Safe checks if v > 30)
    // If v is 27 or 28, we need to make it 31 or 32
    if (signature[64] == 27) {
      signature = Uint8List.fromList(
          [...signature.sublist(0, 64), signature[64] + offset]);
    } else if (signature[64] == 28) {
      signature = Uint8List.fromList(
          [...signature.sublist(0, 64), signature[64] + offset]);
    }

    return signature;
  }

  /// Constructs the authorization URL for Monerium OAuth flow
  ///
  /// [clientId] - Your Monerium client UUID
  /// [redirectUri] - The redirect URI registered with your Monerium app
  /// [codeChallenge] - The PKCE code challenge
  /// [address] - Optional Ethereum address for automated wallet connection
  /// [signature] - Optional signature for automated wallet connection
  ///
  /// Returns the authorization URL as a string
  String buildAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    required String codeChallenge,
    String? address,
    String? signature,
  }) {
    final params = <String, String>{
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'chain': 'gnosis',
    };

    // Add optional parameters for automated wallet connection
    if (address != null) {
      params['address'] = address;
    }
    if (signature != null) {
      params['signature'] = signature;
    }

    print('PARAMS ADDRESS: $address');
    print('PARAMS SIGNATURE: $signature');

    final uri = Uri.https('api.monerium.app', _authPath, params);

    return uri.toString();
  }

  /// Exchanges the authorization code for an access token
  ///
  /// [authorizationCode] - The authorization code received from the redirect
  /// [codeVerifier] - The original code verifier used to generate the challenge
  /// [clientId] - Your Monerium client UUID
  /// [redirectUri] - The redirect URI used in the authorization request
  ///
  /// Returns a map containing the token response (access_token, token_type, etc.)
  /// Throws an exception if the token exchange fails
  Future<Map<String, dynamic>> exchangeCodeForToken({
    required String authorizationCode,
    required String codeVerifier,
    required String clientId,
    required String redirectUri,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$_tokenPath');

      final bodyParams = {
        'client_id': clientId,
        'code': authorizationCode,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': codeVerifier,
      };

      final body = bodyParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(
            const Duration(seconds: 60),
          );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Monerium token exchange failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        throw Exception(
          'Token exchange failed: [${response.statusCode}] ${response.reasonPhrase}',
        );
      }

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return responseData as Map<String, dynamic>;
    } catch (e, s) {
      debugPrint('Error exchanging code for token: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }
}
