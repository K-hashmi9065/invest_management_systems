import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Result returned by [PasswordHasher.verifyPasswordDetailed].
class PasswordVerifyResult {
  /// Whether the supplied password matched the stored hash.
  final bool matched;

  /// True when the match was via the legacy single-round SHA-256 path.
  /// Callers should re-hash the plaintext and persist the new PBKDF2 hash
  /// immediately when this is true.
  final bool usedLegacyHash;

  const PasswordVerifyResult({
    required this.matched,
    required this.usedLegacyHash,
  });
}

class PasswordHasher {
  PasswordHasher._();

  static const int _defaultIterations = 100000;
  static const int _keyLength = 32;

  /// Generate random hex salt
  static String generateSalt([int length = 16]) {
    final Random random = Random.secure();
    final List<int> values = List<int>.generate(length, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// PBKDF2 HMAC-SHA256 key derivation function
  static Uint8List pbkdf2(String password, List<int> saltBytes, int iterations, int keyLength) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final result = Uint8List(keyLength);
    int offset = 0;
    int blockIndex = 1;

    while (offset < keyLength) {
      final blockInput = Uint8List(saltBytes.length + 4);
      blockInput.setAll(0, saltBytes);
      final bd = ByteData.view(blockInput.buffer);
      bd.setUint32(saltBytes.length, blockIndex, Endian.big);

      var u = Uint8List.fromList(hmac.convert(blockInput).bytes);
      final block = Uint8List.fromList(u);

      for (int i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (int j = 0; j < block.length; j++) {
          block[j] ^= u[j];
        }
      }

      final count = min(keyLength - offset, block.length);
      result.setRange(offset, offset + count, block);
      offset += count;
      blockIndex++;
    }
    return result;
  }

  /// Hash password with given salt using PBKDF2 (100,000 iterations)
  static String hashPassword(String password, String salt, [int iterations = _defaultIterations]) {
    final saltBytes = utf8.encode(salt);
    final derived = pbkdf2(password, saltBytes, iterations, _keyLength);
    final hexKey = derived.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'pbkdf2_sha256\$$iterations\$$hexKey';
  }

  /// Constant-time comparison of two hex strings (converted to bytes).
  /// Returns true only when both strings encode identical byte sequences AND
  /// have equal length — accumulates XOR differences without short-circuiting.
  static bool _constantTimeEquals(String a, String b) {
    // Operate on UTF-8 bytes so length mismatches don't short-circuit.
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);

    // Walk the full length of the longer string so we never return early.
    final maxLen = aBytes.length > bBytes.length ? aBytes.length : bBytes.length;
    int diff = aBytes.length ^ bBytes.length; // non-zero if lengths differ
    for (int i = 0; i < maxLen; i++) {
      final aByte = i < aBytes.length ? aBytes[i] : 0;
      final bByte = i < bBytes.length ? bBytes[i] : 0;
      diff |= aByte ^ bByte;
    }
    return diff == 0;
  }

  /// Verify plaintext password against stored hash and salt.
  /// Returns a plain bool for callers that don't need upgrade signalling
  /// (e.g. settings page password confirmation).
  static bool verifyPassword(String password, String storedHash, String salt) {
    return verifyPasswordDetailed(password, storedHash, salt).matched;
  }

  /// Verify plaintext password and report which verification path succeeded.
  /// Use this during login so the caller can trigger a re-hash when
  /// [PasswordVerifyResult.usedLegacyHash] is true.
  static PasswordVerifyResult verifyPasswordDetailed(
      String password, String storedHash, String salt) {
    if (storedHash.startsWith('pbkdf2_sha256\$')) {
      final parts = storedHash.split('\$');
      if (parts.length != 3) {
        return const PasswordVerifyResult(matched: false, usedLegacyHash: false);
      }
      final iterations = int.tryParse(parts[1]) ?? _defaultIterations;
      final computed = hashPassword(password, salt, iterations);
      final matched = _constantTimeEquals(computed, storedHash);
      return PasswordVerifyResult(matched: matched, usedLegacyHash: false);
    }

    // Fallback: legacy single-round SHA-256
    final legacyHash = sha256.convert(utf8.encode(password + salt)).toString();
    final matched = _constantTimeEquals(legacyHash, storedHash);
    return PasswordVerifyResult(matched: matched, usedLegacyHash: true);
  }
}
