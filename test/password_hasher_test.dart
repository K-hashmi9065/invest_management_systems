// Test file for Fix A (legacy hash upgrade on login) and Fix E (constant-time comparison).
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:invest_management_systems/core/security/password_hasher.dart';
import 'package:invest_management_systems/core/database/database_helper.dart';
import 'package:invest_management_systems/core/database/app_repository.dart';
import 'package:invest_management_systems/core/utils/date_formatter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Each test gets a fresh in-memory database.
    DatabaseHelper.testDbPath = inMemoryDatabasePath;
    await DatabaseHelper.resetForTest();
  });

  tearDown(() async {
    await DatabaseHelper.resetForTest();
    DatabaseHelper.testDbPath = null;
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Fix E: PasswordHasher.verifyPassword correctness (constant-time path)
  // ────────────────────────────────────────────────────────────────────────────
  group('PasswordHasher – Fix E: constant-time comparison', () {
    test('verifyPassword returns true for matching PBKDF2 password', () {
      const password = 'MyS3cret!';
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hashPassword(password, salt);
      expect(PasswordHasher.verifyPassword(password, hash, salt), isTrue);
    });

    test('verifyPassword returns false for wrong PBKDF2 password', () {
      const password = 'MyS3cret!';
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hashPassword(password, salt);
      expect(PasswordHasher.verifyPassword('wrong', hash, salt), isFalse);
    });

    test('verifyPassword returns true for matching legacy SHA-256 password', () {
      const password = 'legacyPass';
      const salt = 'deadbeef';
      final legacyHash =
          sha256.convert(utf8.encode(password + salt)).toString();
      expect(PasswordHasher.verifyPassword(password, legacyHash, salt), isTrue);
    });

    test('verifyPassword returns false for wrong legacy SHA-256 password', () {
      const password = 'legacyPass';
      const salt = 'deadbeef';
      final legacyHash =
          sha256.convert(utf8.encode(password + salt)).toString();
      expect(PasswordHasher.verifyPassword('wrong', legacyHash, salt), isFalse);
    });

    test('verifyPasswordDetailed reports usedLegacyHash=false for PBKDF2', () {
      const password = 'S3cur3!';
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hashPassword(password, salt);
      final result = PasswordHasher.verifyPasswordDetailed(password, hash, salt);
      expect(result.matched, isTrue);
      expect(result.usedLegacyHash, isFalse);
    });

    test('verifyPasswordDetailed reports usedLegacyHash=true for legacy hash', () {
      const password = 'legacyPass';
      const salt = 'deadbeef';
      final legacyHash =
          sha256.convert(utf8.encode(password + salt)).toString();
      final result =
          PasswordHasher.verifyPasswordDetailed(password, legacyHash, salt);
      expect(result.matched, isTrue);
      expect(result.usedLegacyHash, isTrue);
    });

    // Timing is not verifiable via flutter test — noted in report.
  });

  // ────────────────────────────────────────────────────────────────────────────
  // Fix A: Legacy hash upgrade on login
  // ────────────────────────────────────────────────────────────────────────────
  group('AppRepository.login – Fix A: legacy hash upgrade', () {
    test('legacy SHA-256 hash is upgraded to PBKDF2 after first login', () async {
      final repo = AppRepository();
      final db = await DatabaseHelper.instance.database;

      // Seed a user with a legacy single-round SHA-256 hash.
      const username = 'legacyuser';
      const password = 'OldPass123';
      const salt = 'aabbccdd';
      final legacyHash = sha256.convert(utf8.encode(password + salt)).toString();
      final now = DateFormatter.toIso(DateTime.now());

      await db.insert('users', {
        'username': username,
        'password_hash': legacyHash,
        'salt': salt,
        'full_name': 'Legacy User',
        'role': 'MEMBER',
        'created_at': now,
      });

      // 1st login — should succeed via legacy path.
      final user = await repo.login(username, password);
      expect(user, isNotNull,
          reason: 'Login should succeed with legacy hash');

      // After login, the stored hash must be in PBKDF2 format.
      final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
      final storedHash = rows.first['password_hash'] as String;
      expect(storedHash, startsWith('pbkdf2_sha256\$'),
          reason: 'Legacy hash must be upgraded to PBKDF2 after first login');

      // 2nd login — must still succeed via the new PBKDF2 hash.
      final user2 = await repo.login(username, password);
      expect(user2, isNotNull,
          reason: 'Second login should succeed via upgraded PBKDF2 hash');
    });

    test('PBKDF2 hash is NOT re-hashed on login', () async {
      final repo = AppRepository();
      final db = await DatabaseHelper.instance.database;

      const username = 'pbkdf2user';
      const password = 'StrongPass!';
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hashPassword(password, salt);
      final now = DateFormatter.toIso(DateTime.now());

      await db.insert('users', {
        'username': username,
        'password_hash': hash,
        'salt': salt,
        'full_name': 'PBKDF2 User',
        'role': 'MEMBER',
        'created_at': now,
      });

      await repo.login(username, password);

      final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
      final storedHashAfter = rows.first['password_hash'] as String;

      // Hash must be unchanged — same object, no re-hash.
      expect(storedHashAfter, equals(hash),
          reason: 'PBKDF2 hash must not be changed after login');
    });

    test('wrong password returns null and does not upgrade hash', () async {
      final repo = AppRepository();
      final db = await DatabaseHelper.instance.database;

      const username = 'wrongpassuser';
      const salt = 'aabbccdd';
      const password = 'correct';
      final legacyHash = sha256.convert(utf8.encode(password + salt)).toString();
      final now = DateFormatter.toIso(DateTime.now());

      await db.insert('users', {
        'username': username,
        'password_hash': legacyHash,
        'salt': salt,
        'full_name': 'Wrong Pass User',
        'role': 'MEMBER',
        'created_at': now,
      });

      final user = await repo.login(username, 'wrong_password');
      expect(user, isNull);

      // Hash must remain legacy — wrong password should not trigger upgrade.
      final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
      expect(rows.first['password_hash'], equals(legacyHash));
    });
  });
}
