import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_app/services/config/service.dart';
import 'package:pay_app/services/monerium/monerium_auth_service.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  setUp(() async {
    // Initialize dotenv
    await dotenv.load(fileName: '.env');
  });

  test('should sign message and verify signature against Safe using ERC1271',
      () async {
    // Get environment variables
    final ownerKeyHex = dotenv.env['TEST_ACCOUNT_OWNER_KEY'];
    final ownerAddress = dotenv.env['TEST_ACCOUNT_OWNER_ADDRESS'];
    final safeAddress = dotenv.env['TEST_ACCOUNT_ADDRESS'];

    if (ownerKeyHex == null || ownerKeyHex.isEmpty) {
      throw Exception('TEST_ACCOUNT_OWNER_KEY not found in .env');
    }
    if (ownerAddress == null || ownerAddress.isEmpty) {
      throw Exception('TEST_ACCOUNT_OWNER_ADDRESS not found in .env');
    }
    if (safeAddress == null || safeAddress.isEmpty) {
      throw Exception('TEST_ACCOUNT_ADDRESS not found in .env');
    }

    // Load config
    final configService = ConfigService();
    final config = await configService.getLocalConfig();
    if (config == null) {
      throw Exception('Failed to load config');
    }

    // Create private key from hex
    final privateKey = EthPrivateKey.fromHex(ownerKeyHex);
    final expectedOwnerAddress = privateKey.address;

    // Verify owner address matches
    expect(
      expectedOwnerAddress.hexEip55.toLowerCase(),
      ownerAddress.toLowerCase(),
      reason: 'Private key address should match TEST_ACCOUNT_OWNER_ADDRESS',
    );

    // Get SimpleAccount for the Safe
    final simpleAccount = await config.getSimpleAccount(safeAddress);

    // The message to sign
    const message = 'I hereby declare that I am the address owner.';
    final messageBytes = utf8.encode(message);

    // Encode message data for Safe (this is what Safe expects as _data parameter)
    final preMessage =
        await simpleAccount.encodeMessageDataForSafe(messageBytes);

    // Get message hash for Safe - this is what Safe will check against
    // Pass messageBytes directly (not preMessage) to match what Safe will do internally
    final messageHash = await simpleAccount.getMessageHashForSafe(messageBytes);

    // Try different hashes to sign with personal sign (like Safe SDK does)
    // Safe SDK: hashSafeMessage(message.data) = keccak256(message.data)
    // Then gets safeMessageHash and signs it
    final hashOfMessage = keccak256(messageBytes);
    final hashOfPreMessage = keccak256(preMessage);

    // Try signing messageHash with personal sign and adjust v for eth_sign flow (v > 30)
    // Safe's checkSignatures will handle eth_sign flow when v > 30
    var signature = privateKey.signPersonalMessageToUint8List(messageHash);

    // Adjust v for eth_sign flow (Safe checks if v > 30)
    // If v is 27 or 28, we need to make it 31 or 32
    if (signature[64] == 27) {
      signature = Uint8List.fromList([...signature.sublist(0, 64), 31]);
    } else if (signature[64] == 28) {
      signature = Uint8List.fromList([...signature.sublist(0, 64), 32]);
    }

    // Verify signature is 65 bytes
    expect(signature.length, equals(65),
        reason: 'Signature should be 65 bytes');

    // Recover address from signature to verify it matches
    // For eth_sign flow (v > 30), Safe uses: ecrecover(keccak256("\x19Ethereum Signed Message:\n32" + dataHash), v - 4, r, s)
    // So we need to recover from the personal sign hash
    final personalSignHash = keccak256(Uint8List.fromList([
      ...utf8.encode('\x19Ethereum Signed Message:\n32'),
      ...messageHash,
    ]));
    final recoveredMsgSig = MsgSignature(
      hexToInt(bytesToHex(signature.sublist(0, 32), include0x: true)),
      hexToInt(bytesToHex(signature.sublist(32, 64), include0x: true)),
      signature[64] - 4, // Adjust v back for recovery
    );
    final recoveredPubKey = ecRecover(personalSignHash, recoveredMsgSig);
    final recoveredAddress = EthereumAddress.fromPublicKey(recoveredPubKey);

    // Print debug information
    print('Owner Address: ${expectedOwnerAddress.hexEip55}');
    print('Recovered Address: ${recoveredAddress.hexEip55}');
    print(
        'Addresses match: ${expectedOwnerAddress.hexEip55.toLowerCase() == recoveredAddress.hexEip55.toLowerCase()}');
    print('Safe Address: $safeAddress');
    print('Message: $message');
    print('PreMessage: ${bytesToHex(preMessage, include0x: true)}');
    print('Message Hash: ${bytesToHex(messageHash, include0x: true)}');
    print('Hash of Message: ${bytesToHex(hashOfMessage, include0x: true)}');
    print(
        'Hash of PreMessage: ${bytesToHex(hashOfPreMessage, include0x: true)}');
    print('Signature: ${bytesToHex(signature, include0x: true)}');
    print('Signature v: ${signature[64]}');

    // Verify signature against Safe using isValidSignature
    // Pass messageBytes (not preMessage) so Safe encodes it once
    // Safe will: encodeMessageDataForSafe(safe, messageBytes) -> preMessage
    // Then: keccak256(preMessage) -> messageHash (which we signed)
    // Then: checkSignatures(messageHash, preMessage, signature)
    final result =
        await simpleAccount.isValidSignature(messageBytes, signature);

    // Print result
    print('isValidSignature result: ${bytesToHex(result, include0x: true)}');

    // ERC1271 magic values:
    // - Legacy: 0x1626ba7e (EIP1271_MAGIC_VALUE)
    // - Updated: 0x20c13b0b (UPDATED_MAGIC_VALUE) - for the updated isValidSignature(bytes32, bytes)
    final legacyMagicValue = hexToBytes('0x1626ba7e');
    final updatedMagicValue = hexToBytes('0x20c13b0b');

    final isLegacyValid = result.length == 4 &&
        result[0] == legacyMagicValue[0] &&
        result[1] == legacyMagicValue[1] &&
        result[2] == legacyMagicValue[2] &&
        result[3] == legacyMagicValue[3];

    final isUpdatedValid = result.length == 4 &&
        result[0] == updatedMagicValue[0] &&
        result[1] == updatedMagicValue[1] &&
        result[2] == updatedMagicValue[2] &&
        result[3] == updatedMagicValue[3];

    final isValid = isLegacyValid || isUpdatedValid;

    print('Signature valid: $isValid');
    print('Legacy magic value match: $isLegacyValid');
    print('Updated magic value match: $isUpdatedValid');

    // Assert that the signature is valid
    expect(isValid, isTrue,
        reason: 'Signature should be valid (return magic value)');
  });
}
