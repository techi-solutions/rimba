import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:pay_app/services/wallet/utils.dart';
import 'package:pay_app/services/monerium/monerium_auth_service.dart';

void main() {
  test('should recover address from signature created by signOwnershipMessage',
      () {
    // Create a private key
    final privateKey = EthPrivateKey.createRandom(Random.secure());
    final expectedAddress = privateKey.address;

    // Sign the message using signOwnershipMessage
    final authService = MoneriumAuthService();
    final signature = authService.signOwnershipMessage(
      privateKey: privateKey,
    );

    // Verify signature is 65 bytes
    expect(signature.length, equals(65));

    // Verify v is 27 or 28
    final vByte = signature[64];
    expect(vByte == 27 || vByte == 28, isTrue,
        reason: 'v should be 27, 28, or 0');

    // Reconstruct the message hash using hashSignatureData (same as signPersonalMessageToUint8List does)
    // signPersonalMessageToUint8List expects raw message bytes, adds prefix, then hashes
    const message = 'I hereby declare that I am the address owner.';
    final messageBytes = utf8.encode(message);
    final messageHash = hashSignatureData(messageBytes);

    // Parse signature components manually to avoid issues with bytesToInt
    final rBytes = signature.sublist(0, 32);
    final sBytes = signature.sublist(32, 64);
    final r = hexToInt(bytesToHex(rBytes, include0x: true));
    final s = hexToInt(bytesToHex(sBytes, include0x: true));

    // v is 27 or 28, but ecRecover expects recovery ID (0 or 1) when hash is prefixed
    // However, web3dart's ecRecover actually expects 27 or 28 for personal messages
    final msgSig = MsgSignature(r, s, vByte);
    final pubKey = ecRecover(messageHash, msgSig);
    final recoveredAddress = EthereumAddress.fromPublicKey(pubKey);

    // Verify the recovered address matches the private key address
    expect(
      recoveredAddress.hex.toLowerCase(),
      equals(expectedAddress.hex.toLowerCase()),
      reason:
          'Recovered address should match the private key address that signed the message',
    );
  });

  test('should recover correct key address from known signature', () {
    // Given: Known signature and key address
    const keyAddress = '0xdF536f02BF4B5d51b2E47369E2d67517F60c4785';
    const signatureHex =
        '0xdb6f0a8412259287b934f64956df03b841c9d440b6a2bf4d55920be7a59edf9414c22ce067a486ea548472eebcc560c4dbc6f6e4de7ecfae751a89b60b3f546d1b';
    const message = 'I hereby declare that I am the address owner.';

    // Convert signature hex to Uint8List
    final signature = hexToBytes(signatureHex);

    // Verify signature is 65 bytes
    expect(signature.length, equals(65));

    // Parse signature components
    final rBytes = signature.sublist(0, 32);
    final sBytes = signature.sublist(32, 64);
    final vByte = signature[64];

    // Verify v is 27 or 28
    expect(vByte == 27 || vByte == 28, isTrue, reason: 'v should be 27 or 28');

    // Reconstruct the message hash using hashSignatureData
    // signPersonalMessageToUint8List expects raw message bytes, adds prefix, then hashes
    final messageBytes = utf8.encode(message);
    final messageHash = hashSignatureData(messageBytes);

    // Convert bytes to BigInt using hex conversion to ensure unsigned
    final r = hexToInt(bytesToHex(rBytes, include0x: true));
    final s = hexToInt(bytesToHex(sBytes, include0x: true));

    // Recover the address from the signature
    final msgSig = MsgSignature(r, s, vByte);
    final pubKey = ecRecover(messageHash, msgSig);
    final recoveredAddress = EthereumAddress.fromPublicKey(pubKey);

    // Verify the recovered address matches the key address
    expect(
      recoveredAddress.hex.toLowerCase(),
      equals(keyAddress.toLowerCase()),
      reason:
          'Recovered address should match the key address that signed the message',
    );
  });
}
