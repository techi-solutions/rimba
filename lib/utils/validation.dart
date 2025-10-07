/// Utility functions for validation
class ValidationUtils {
  /// Validate email format using regex
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  /// Check if a string is a valid transaction hash format
  static bool isValidTxHash(String? txHash) {
    if (txHash == null || txHash.isEmpty) return false;
    return RegExp(r'^0x[a-fA-F0-9]{64}$').hasMatch(txHash);
  }

  /// Check if transaction hash is a mock/development hash
  static bool isMockTxHash(String txHash) {
    return txHash.startsWith('0x00000000000000000000000000000000');
  }
}

