import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class SecureService {
  static final SecureService _instance = SecureService._internal();

  factory SecureService() => _instance;
  SecureService._internal();

  static const String _versionKey = 'secure_version';
  static const int version = 1;

  late SharedPreferences _preferences;

  static const String _privateKeyKey = 'ethereum_private_key';
  static const String _moneriumTokenKey = 'monerium_access_token';
  static const String _moneriumRefreshTokenKey = 'monerium_refresh_token';
  static const String _moneriumTokenExpiryKey = 'monerium_token_expiry';

  Future init(SharedPreferences pref) async {
    _preferences = pref;

    final version = _preferences.getInt(_versionKey);
    if (version == null || version < SecureService.version) {
      await migrate(version ?? 0, SecureService.version);
    }
  }

  Future migrate(int oldVersion, int newVersion) async {
    switch (newVersion) {
      case 1:
        // migrate to version 1
        _preferences.setInt(_versionKey, newVersion);
        break;
      default:
    }
  }

  Future clear() async {
    await _preferences.clear();
  }

  // Save private key with account address
  Future setCredentials(
      EthereumAddress accountAddress, EthPrivateKey privateKey) async {
    final privateKeyHex = bytesToHex(privateKey.privateKey);
    final storedValue = '${accountAddress.hexEip55}:$privateKeyHex';
    await _preferences.setString(_privateKeyKey, storedValue);
  }

  // Get private key without needing arguments
  (EthereumAddress, EthPrivateKey)? getCredentials() {
    final storedValue = _preferences.getString(_privateKeyKey);
    if (storedValue == null) {
      return null;
    }

    try {
      final parts = storedValue.split(':');
      if (parts.length != 2) {
        return null;
      }

      final accountAddress = parts[0];
      final privateKeyHex = parts[1];
      final privateKey = EthPrivateKey.fromHex(privateKeyHex);
      return (
        EthereumAddress.fromHex(accountAddress),
        privateKey,
      );
    } catch (e) {
      return null;
    }
  }

  // Get account address associated with the stored private key
  String? getAccountAddress() {
    final storedValue = _preferences.getString(_privateKeyKey);
    if (storedValue == null) return null;

    final parts = storedValue.split(':');
    if (parts.length != 2) return null;

    return parts[0];
  }

  // Check if a private key is stored
  bool hasCredentials() {
    return _preferences.containsKey(_privateKeyKey);
  }

  // Delete the stored private key
  Future clearCredentials() async {
    await _preferences.remove(_privateKeyKey);
  }

  // Monerium token management
  Future setMoneriumTokens({
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
  }) async {
    await _preferences.setString(_moneriumTokenKey, accessToken);
    if (refreshToken != null) {
      await _preferences.setString(_moneriumRefreshTokenKey, refreshToken);
    }
    if (expiresIn != null) {
      final expiryTime =
          DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
      await _preferences.setInt(_moneriumTokenExpiryKey, expiryTime);
    }
  }

  String? getMoneriumAccessToken() {
    return _preferences.getString(_moneriumTokenKey);
  }

  String? getMoneriumRefreshToken() {
    return _preferences.getString(_moneriumRefreshTokenKey);
  }

  int? getMoneriumTokenExpiry() {
    return _preferences.getInt(_moneriumTokenExpiryKey);
  }

  bool hasMoneriumTokens() {
    return _preferences.containsKey(_moneriumTokenKey);
  }

  bool isMoneriumTokenExpired() {
    final expiry = getMoneriumTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= expiry;
  }

  Future clearMoneriumTokens() async {
    await _preferences.remove(_moneriumTokenKey);
    await _preferences.remove(_moneriumRefreshTokenKey);
    await _preferences.remove(_moneriumTokenExpiryKey);
  }
}
