import 'dart:convert';

import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    const sep = Money.groupSeparator;

    test('groups thousands with the separator', () {
      expect(Money.group(1234567), '1${sep}234${sep}567');
      expect(Money.group(0), '0');
      expect(Money.group(999), '999');
      expect(Money.group(-12000), '-12${sep}000');
    });

    test('formats with the UZS suffix', () {
      expect(Money.format(120000), '120${sep}000$sep${Money.suffix}');
      expect(Money.format(120000, withSuffix: false), '120${sep}000');
    });
  });

  group('Validators', () {
    test('accepts a valid UZ phone and normalizes formatting', () {
      expect(Validators.phone('+998 (90) 123-45-67'), isNull);
      expect(Validators.normalizePhone('90 123 45 67'), '+998901234567');
    });

    test('rejects malformed phones', () {
      expect(Validators.phone('12345'), FailureCode.invalidPhone);
      expect(Validators.phone(''), FailureCode.invalidPhone);
    });

    test('royalty bounds are enforced', () {
      expect(Validators.royalty(AppConstants.royaltyMinUzs), isNull);
      expect(Validators.royalty(AppConstants.royaltyMaxUzs), isNull);
      expect(
        Validators.royalty(AppConstants.royaltyMinUzs - 1),
        FailureCode.royaltyOutOfBounds,
      );
    });

    test('otp must be the configured number of digits', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('12345'), FailureCode.otpWrong);
      expect(Validators.otp('12345a'), FailureCode.otpWrong);
    });
  });

  group('Result', () {
    test('fold dispatches on the branch', () {
      const Result<int> ok = Success(5);
      const Result<int> bad = Failure('nope', code: FailureCode.server);
      expect(ok.fold((d) => d * 2, (_) => -1), 10);
      expect(bad.fold((d) => d, (f) => f.code), FailureCode.server);
    });

    test('map preserves failures', () {
      const Result<int> bad = Failure('nope', code: FailureCode.network);
      final mapped = bad.map((d) => d.toString());
      expect(mapped.isFailure, isTrue);
      expect((mapped as Failure).code, FailureCode.network);
    });
  });

  group('LedgerEntry', () {
    test('balance-relevant sign is exposed', () {
      final credit = LedgerEntry.fromJson(const {
        'id': '1',
        'designer_id': 'd',
        'type': 'royaltyAccrued',
        'amount': 5000,
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(credit.isCredit, isTrue);
      expect(credit.type, LedgerEntryType.royaltyAccrued);
    });
  });

  group('Jwt', () {
    String tokenWithSub(String sub) {
      final payload = base64Url
          .encode(utf8.encode(json.encode({'sub': sub})))
          .replaceAll('=', '');
      return 'header.$payload.signature';
    }

    test('reads the sub claim', () {
      expect(Jwt.subject(tokenWithSub('user-123')), 'user-123');
    });

    test('returns null for malformed tokens', () {
      expect(Jwt.subject(null), isNull);
      expect(Jwt.subject('not-a-jwt'), isNull);
    });
  });

  group('ErrorMapper', () {
    test('maps an ApiException to its FailureCode', () {
      final failure = ErrorMapper.toFailure<int>(
        ApiException(FailureCode.otpWrong, 'bad code', statusCode: 422),
      );
      expect(failure.code, FailureCode.otpWrong);
      expect(failure.message, 'bad code');
    });

    test('falls back to server for unknown errors', () {
      final failure = ErrorMapper.toFailure<int>(StateError('boom'));
      expect(failure.code, FailureCode.server);
    });
  });
}
