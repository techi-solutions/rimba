import 'dart:typed_data';

/// Model for email session request data
class EmailSessionRequest {
  final String provider;
  final String owner;
  final String source;
  final String type;
  final int expiry;
  final String signature;

  const EmailSessionRequest({
    required this.provider,
    required this.owner,
    required this.source,
    required this.type,
    required this.expiry,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'owner': owner,
        'source': source,
        'type': type,
        'expiry': expiry,
        'signature': signature,
      };
}

/// Model for email session confirmation data
class EmailSessionConfirmation {
  final String provider;
  final String owner;
  final String hash;
  final int challenge;
  final String signature;

  const EmailSessionConfirmation({
    required this.provider,
    required this.owner,
    required this.hash,
    required this.challenge,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'owner': owner,
        'hash': hash,
        'challenge': challenge,
        'signature': signature,
      };
}

/// Model for session response data
class SessionResponse {
  final String sessionRequestTxHash;
  final Uint8List hash;
  final String email;

  const SessionResponse({
    required this.sessionRequestTxHash,
    required this.hash,
    required this.email,
  });
}

