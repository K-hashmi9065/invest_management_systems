import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invest_management_systems/core/calculations/contribution_calculator.dart';
import 'package:invest_management_systems/core/calculations/profit_calculator.dart';
import 'package:invest_management_systems/core/security/password_hasher.dart';
import 'package:invest_management_systems/core/utils/currency_formatter.dart';

void main() {
  group('Financial Calculations Tests', () {
    test('Currency Formatter - Paise to Rupees & Compact', () {
      expect(CurrencyFormatter.formatPaise(10000000), '₹1,00,000.00');
      expect(CurrencyFormatter.rupeesToPaise(5000.50), 500050);
      expect(CurrencyFormatter.paiseToRupees(500050), 5000.50);
    });

    test('Contribution Percentage Formula uses ContributionCalculator', () {
      const totalGroupContribPaise = 100000000; // 10,00,000 INR
      const memberContribPaise = 20000000; // 2,00,000 INR

      final double percentage = ContributionCalculator.percentageOf(
        memberContribPaise,
        totalGroupContribPaise,
      );
      expect(percentage, 20.0);
    });

    test('Contribution Percentage Edge Case - Zero Total Contribution', () {
      final double percentage = ContributionCalculator.percentageOf(5000, 0);
      expect(percentage, 0.0);
    });

    test('Pro-Rata Profit Distribution Calculation uses ProfitCalculator', () {
      const totalInvestmentProfitPaise = 10000000; // 1,00,000 INR
      const memberPercentage = 20.0;

      final int memberProfitSharePaise = ProfitCalculator.memberShare(
        totalInvestmentProfitPaise,
        memberPercentage,
      );
      expect(memberProfitSharePaise, 2000000); // 20,000 INR
    });

    test('Pro-Rata Profit Distribution Edge Case - Negative Profit (Loss)', () {
      const totalInvestmentLossPaise = -5000000; // -50,000 INR
      const memberPercentage = 25.0;

      final int memberLossSharePaise = ProfitCalculator.memberShare(
        totalInvestmentLossPaise,
        memberPercentage,
      );
      expect(memberLossSharePaise, -1250000); // -12,500 INR
    });

    test('Password Hasher & Verification Round-trip', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hashPassword('SuperSecret123', salt);

      expect(PasswordHasher.verifyPassword('SuperSecret123', hash, salt), isTrue);
      expect(PasswordHasher.verifyPassword('WrongPassword', hash, salt), isFalse);
    });

    test('Password Hasher PBKDF2 differs from plain single-round SHA-256', () {
      const password = 'TestPassword123';
      final salt = PasswordHasher.generateSalt();

      final plainSha256Hash = sha256.convert(utf8.encode(password + salt)).toString();
      final pbkdf2Hash = PasswordHasher.hashPassword(password, salt);

      expect(pbkdf2Hash, isNot(equals(plainSha256Hash)));
      expect(pbkdf2Hash, startsWith('pbkdf2_sha256\$100000\$'));
    });

    test('Password Hasher determinism and salt uniqueness', () {
      const password = 'MySecurePassword';
      final salt1 = PasswordHasher.generateSalt();
      final salt2 = PasswordHasher.generateSalt();

      final hash1a = PasswordHasher.hashPassword(password, salt1);
      final hash1b = PasswordHasher.hashPassword(password, salt1);
      final hash2 = PasswordHasher.hashPassword(password, salt2);

      expect(hash1a, equals(hash1b));
      expect(hash1a, isNot(equals(hash2)));
    });
  });
}
