import 'package:flutter_test/flutter_test.dart';
import 'package:tongtai/features/tongtai/export/backup_crypto.dart';

/// WTM-100 — passphrase-encrypted backups: armored v1 container, AES-256-GCM
/// over a PBKDF2 key. Low iteration count here purely for test speed; the
/// container format is identical.
void main() {
  const crypto = BackupCrypto(iterations: 10);
  const secret = 'mật-khẩu-rất-mạnh';
  const plaintext = '\u{FEFF}name,phone\nThu Hà,0901234567\n';

  test('round-trip: encrypt → armored container → decrypt', () async {
    final armored = await crypto.encryptArmored(plaintext, secret);

    expect(BackupCrypto.isArmored(armored), isTrue);
    expect(armored, startsWith('TONGTAI-BACKUP-V1:'));
    expect(armored, isNot(contains('Thu Hà'))); // nothing leaks in the clear

    expect(await crypto.decryptArmored(armored, secret), plaintext);
  });

  test('every encryption is unique (fresh salt + nonce)', () async {
    final a = await crypto.encryptArmored(plaintext, secret);
    final b = await crypto.encryptArmored(plaintext, secret);
    expect(a, isNot(b));
    // Both still decrypt to the same plaintext.
    expect(await crypto.decryptArmored(a, secret), plaintext);
    expect(await crypto.decryptArmored(b, secret), plaintext);
  });

  test('wrong passphrase → friendly BackupCryptoException', () async {
    final armored = await crypto.encryptArmored(plaintext, secret);
    await expectLater(
      crypto.decryptArmored(armored, 'sai-mật-khẩu'),
      throwsA(isA<BackupCryptoException>()),
    );
  });

  test('tampered ciphertext is rejected (GCM auth)', () async {
    final armored = await crypto.encryptArmored(plaintext, secret);
    // Flip one character deep inside the base64 payload.
    final index = armored.length - 10;
    final flipped = armored.replaceRange(
      index,
      index + 1,
      armored[index] == 'A' ? 'B' : 'A',
    );
    await expectLater(
      crypto.decryptArmored(flipped, secret),
      throwsA(isA<BackupCryptoException>()),
    );
  });

  test('malformed containers → friendly errors, never crashes', () async {
    await expectLater(
      crypto.decryptArmored('not-a-backup', secret),
      throwsA(isA<BackupCryptoException>()),
    );
    await expectLater(
      crypto.decryptArmored('TONGTAI-BACKUP-V1:@@không-phải-base64@@', secret),
      throwsA(isA<BackupCryptoException>()),
    );
    await expectLater(
      crypto.decryptArmored('TONGTAI-BACKUP-V1:AAAA', secret), // too short
      throwsA(isA<BackupCryptoException>()),
    );
  });
}
