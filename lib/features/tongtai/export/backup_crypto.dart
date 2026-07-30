import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Passphrase encryption for Tổng Tài backups (WTM-100, Founder-approved).
///
/// Container is **armored text** so it flows through the existing CSV delivery
/// seam unchanged:
///
/// ```text
/// TONGTAI-BACKUP-V1:<base64(salt(16) | iterations(4, big-endian) |
///                           nonce(12) | ciphertext+tag)>
/// ```
///
/// The KDF iteration count is embedded so old backups keep decrypting even if
/// the app's default changes later.
///
/// Crypto: AES-256-GCM with a PBKDF2-HMAC-SHA256 key (150k iterations by
/// default; injectable so tests stay fast). Pure Dart (`cryptography` package)
/// — no platform channels, works everywhere the app does. Local-first: the
/// passphrase never leaves the device and is never stored.
class BackupCrypto {
  const BackupCrypto({this.iterations = 150000});

  /// The armor prefix identifying a Tổng Tài encrypted backup, version 1.
  static const String header = 'TONGTAI-BACKUP-V1:';

  static const int _saltLength = 16;
  static const int _itersLength = 4;
  static const int _nonceLength = 12;

  /// Upper bound accepted when reading a container — rejects absurd values in
  /// crafted files (a CPU-exhaustion guard), generous for honest ones.
  static const int _maxIterations = 5000000;

  /// PBKDF2 iteration count — the default is phone-friendly; tests inject a
  /// small value for speed.
  final int iterations;

  AesGcm get _cipher => AesGcm.with256bits();

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt, int rounds) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: rounds,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  /// Encrypts [plaintext] under [passphrase] into the armored container.
  Future<String> encryptArmored(String plaintext, String passphrase) async {
    final cipher = _cipher;
    final rnd = Random.secure();
    final salt = List<int>.generate(_saltLength, (_) => rnd.nextInt(256));
    final key = await _deriveKey(passphrase, salt, iterations);
    final box = await cipher.encrypt(utf8.encode(plaintext), secretKey: key);
    final iters = ByteData(_itersLength)..setUint32(0, iterations);
    final packed = Uint8List.fromList([
      ...salt,
      ...iters.buffer.asUint8List(),
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
    return '$header${base64Encode(packed)}';
  }

  /// True when [armored] carries the v1 backup header.
  static bool isArmored(String armored) => armored.startsWith(header);

  /// Decrypts a v1 armored container back to the plaintext. Throws
  /// [BackupCryptoException] for a malformed container, a wrong passphrase, or
  /// tampered data (GCM authentication failure).
  Future<String> decryptArmored(String armored, String passphrase) async {
    if (!isArmored(armored)) {
      throw const BackupCryptoException(
        'Không phải file backup Tổng Tài (thiếu header). '
        '(Not a Tổng Tài backup container.)',
      );
    }
    final Uint8List packed;
    try {
      packed = base64Decode(armored.substring(header.length).trim());
    } on FormatException {
      throw const BackupCryptoException(
        'File backup bị hỏng (base64 không hợp lệ). (Corrupted container.)',
      );
    }
    const prefix = _saltLength + _itersLength + _nonceLength;
    const overhead = prefix + 16; // + GCM tag
    if (packed.length < overhead) {
      throw const BackupCryptoException(
        'File backup bị hỏng (quá ngắn). (Container too short.)',
      );
    }
    final salt = packed.sublist(0, _saltLength);
    final rounds = ByteData.sublistView(
      packed,
      _saltLength,
      _saltLength + _itersLength,
    ).getUint32(0);
    if (rounds < 1 || rounds > _maxIterations) {
      throw const BackupCryptoException(
        'File backup bị hỏng (KDF không hợp lệ). (Invalid KDF parameters.)',
      );
    }
    final nonce = packed.sublist(_saltLength + _itersLength, prefix);
    final cipherText = packed.sublist(prefix, packed.length - 16);
    final mac = Mac(packed.sublist(packed.length - 16));
    final key = await _deriveKey(passphrase, salt, rounds);
    try {
      final clear = await _cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: key,
      );
      var text = utf8.decode(clear);
      // Dart's UTF-8 decoder silently strips a leading BOM; our CSV exports
      // carry one by design (WTM-99) — restore it for a byte-exact round-trip.
      final hasBomBytes =
          clear.length >= 3 &&
          clear[0] == 0xEF &&
          clear[1] == 0xBB &&
          clear[2] == 0xBF;
      if (hasBomBytes && !text.startsWith('﻿')) {
        text = '﻿$text';
      }
      return text;
    } on SecretBoxAuthenticationError {
      throw const BackupCryptoException(
        'Sai mật khẩu hoặc file đã bị sửa đổi. '
        '(Wrong passphrase or tampered data.)',
      );
    }
  }
}

/// Friendly, catchable failure for every decrypt problem (never leaks crypto
/// internals to the UI).
class BackupCryptoException implements Exception {
  const BackupCryptoException(this.message);

  final String message;

  @override
  String toString() => message;
}
