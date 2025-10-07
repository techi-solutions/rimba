/// Exception thrown when an invalid challenge is provided
class InvalidChallengeException implements Exception {
  final String message;

  const InvalidChallengeException([this.message = 'Invalid challenge provided']);

  @override
  String toString() => 'InvalidChallengeException: $message';
}

/// Exception thrown when session request fails
class SessionRequestException implements Exception {
  final String message;

  const SessionRequestException(this.message);

  @override
  String toString() => 'SessionRequestException: $message';
}

/// Exception thrown when session confirmation fails
class SessionConfirmationException implements Exception {
  final String message;

  const SessionConfirmationException(this.message);

  @override
  String toString() => 'SessionConfirmationException: $message';
}

/// Exception thrown when API response is invalid
class InvalidApiResponseException implements Exception {
  final String message;
  final dynamic response;

  const InvalidApiResponseException(this.message, [this.response]);

  @override
  String toString() => 'InvalidApiResponseException: $message';
}

