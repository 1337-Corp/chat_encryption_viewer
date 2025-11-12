import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simplified encryption service that demonstrates the same encryption
/// used in the main chuk_chat application.
///
/// This service uses:
/// - AES-256-GCM for encryption
/// - PBKDF2 with 600,000 iterations for key derivation
/// - Client-side encryption (server never sees decrypted data)
class EncryptionDemoService {
  static const String _storagePrefix = 'chat_key_';
  static const String _storageSaltPrefix = 'chat_salt_';
  static const String _payloadVersion = '1';
  static const int _kdfIterations = 600000;
  static const int _saltLength = 16;
  static final AesGcm _cipher = AesGcm.with256bits();
  static final Random _rng = Random.secure();

  static SecretKey? _cachedKey;
  static String? _cachedUserId;

  /// Initialize encryption with password
  static Future<void> initializeForPassword(
    String password,
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saltKey = '$_storageSaltPrefix$userId';
    final keyKey = '$_storagePrefix$userId';

    String? storedSaltBase64 = prefs.getString(saltKey);
    String? storedKeyBase64 = prefs.getString(keyKey);

    // Generate new salt if needed
    if (storedSaltBase64 == null) {
      final salt = _randomNonce(_saltLength);
      storedSaltBase64 = base64Encode(salt);
      await prefs.setString(saltKey, storedSaltBase64);
    }

    final saltBytes = base64Decode(storedSaltBase64);
    final derivedKeyBytes = await _deriveKey(password, saltBytes);

    // Verify password if key exists
    if (storedKeyBase64 != null) {
      final storedKeyBytes = base64Decode(storedKeyBase64);
      if (!_constantTimeEquals(derivedKeyBytes, storedKeyBytes)) {
        throw StateError('Incorrect password provided.');
      }
    } else {
      await prefs.setString(keyKey, base64Encode(derivedKeyBytes));
    }

    _cachedKey = SecretKey(derivedKeyBytes);
    _cachedUserId = userId;
  }

  /// Try to load existing key
  static Future<bool> tryLoadKey(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keyKey = '$_storagePrefix$userId';
    final encoded = prefs.getString(keyKey);

    if (encoded == null) {
      _cachedKey = null;
      _cachedUserId = null;
      return false;
    }

    _cachedKey = SecretKey(base64Decode(encoded));
    _cachedUserId = userId;
    return true;
  }

  /// Encrypt plaintext
  static Future<String> encrypt(String plaintext) async {
    if (_cachedKey == null) {
      throw StateError('Encryption key not initialized');
    }

    final nonce = _randomNonce(12);
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: _cachedKey!,
      nonce: nonce,
    );

    final payload = <String, String>{
      'v': _payloadVersion,
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };

    return jsonEncode(payload);
  }

  /// Decrypt ciphertext
  static Future<String> decrypt(String encrypted) async {
    if (_cachedKey == null) {
      throw StateError('Encryption key not initialized');
    }

    final Map<String, dynamic> payload = jsonDecode(encrypted);
    final version = payload['v'];

    if (version != _payloadVersion) {
      throw StateError('Unsupported ciphertext version: $version');
    }

    final nonce = base64Decode(payload['nonce'] as String);
    final cipherText = base64Decode(payload['ciphertext'] as String);
    final mac = Mac(base64Decode(payload['mac'] as String));

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final cleartextBytes = await _cipher.decrypt(
      secretBox,
      secretKey: _cachedKey!,
    );

    return utf8.decode(cleartextBytes);
  }

  /// Clear cached key
  static void clearKey() {
    _cachedKey = null;
    _cachedUserId = null;
  }

  /// Derive encryption key from password using PBKDF2
  static Future<List<int>> _deriveKey(String password, List<int> salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _kdfIterations,
      bits: 256,
    );

    final newSecretKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    return newSecretKey.extractBytes();
  }

  /// Generate random nonce
  static List<int> _randomNonce(int length) {
    return List<int>.generate(length, (_) => _rng.nextInt(256));
  }

  /// Constant-time comparison to prevent timing attacks
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
