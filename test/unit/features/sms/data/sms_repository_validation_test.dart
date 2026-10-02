import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zexano_sms/core/errors/failures.dart';
import 'package:zexano_sms/core/phone/phone_validator.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';
import 'package:zexano_sms/features/sms/data/dispatchers/sms_dispatcher.dart';
import 'package:zexano_sms/features/sms/data/mappers/sms_mapper.dart';
import 'package:zexano_sms/features/sms/data/repositories/sms_repository_impl.dart';
import 'package:zexano_sms/features/sms/domain/repositories/sms_repository.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';

class MockSmsLocalSource extends Mock implements SmsLocalSource {}
class MockGroupsRepository extends Mock implements GroupsRepository {}
class MockSmsDispatcher extends Mock implements SmsDispatcher {}

void main() {
  late SmsRepository repository;
  late MockSmsLocalSource mockLocalSource;
  late MockGroupsRepository mockGroupsRepository;
  late MockSmsDispatcher mockDispatcher;

  setUpAll(() {
    registerFallbackValue(
      SmsMapper.historyRowCompanion(
        id: 'test-id',
        tenantId: 'test-tenant',
        batchId: 'test-batch',
        targetPhone: '+967771234567',
        messageBody: 'test',
        channelType: 'sms',
        contactName: '',
        timestamp: 0,
        peerId: 'sms:+967771234567',
      ),
    );
  });

  setUp(() {
    mockLocalSource = MockSmsLocalSource();
    mockGroupsRepository = MockGroupsRepository();
    mockDispatcher = MockSmsDispatcher();

    when(() => mockLocalSource.insertHistoryRow(any())).thenAnswer((_) async => 1);
    when(() => mockLocalSource.updateStatusByIdSafe(any(), any(), sentAt: any(named: 'sentAt'))).thenAnswer((_) async {});

    repository = SmsRepositoryImpl(
      localSource: mockLocalSource,
      groupsRepository: mockGroupsRepository,
      dispatcher: mockDispatcher,
      normalizationEngine: NormalizationEngine(),
      phoneValidator: PhoneValidator(),
    );
  });

  group('validateSmsPayload', () {
    test('accepts valid Yemeni number +967771234567', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: ['+967771234567'],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, true);
    });

    test('rejects invalid Yemeni number +967791234567 (bad prefix)', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: ['+967791234567'],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, false);
      expect(validation.errors.any((e) => e.contains('غير صالح')), true);
    });

    test('accepts valid Saudi number +966501234567', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: ['+966501234567'],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, true);
    });

    test('rejects invalid Saudi number +966123 (too short)', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: ['+966123'],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, false);
      expect(validation.errors.any((e) => e.contains('غير صالح')), true);
    });

    test('accepts valid US number +14155552671', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: ['+14155552671'],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, true);
    });

    test('rejects invalid US number +123 (too short)', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: ['+123'],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, false);
      expect(validation.errors.any((e) => e.contains('غير صالح')), true);
    });

    test('rejects valid Saudi number that is too long', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: ['+96650123456789'],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, false);
      expect(validation.errors.any((e) => e.contains('غير صالح')), true);
    });

    test('accepts valid UK number +447700900000', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: ['+447700900000'],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, true);
    });

    test('rejects empty phone number', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: [''],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, false);
    });

    test('accepts multiple valid numbers from different countries', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: [
          '+967771234567',
          '+966501234567',
          '+14155552671',
          '+447700900000',
        ],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, true);
    });

    test('rejects when one number of many is invalid', () async {
      final result = await repository.validateSmsPayload(
        messageBody: 'test message',
        phoneNumbers: [
          '+967771234567',
          '+966123',
        ],
      );
      expect(result.isRight(), true);
      final validation = result.getOrElse(() => throw 'unexpected');
      expect(validation.isValid, false);
      expect(validation.errors.any((e) => e.contains('غير صالح')), true);
    });
  });

  group('sendSingleSms', () {
    test('rejects invalid phone with failure', () async {
      final result = await repository.sendSingleSms(
        messageBody: 'test',
        phoneNumber: '+966123',
      );
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message.contains('غير صالح'), true);
        },
        (_) => fail('expected failure'),
      );
    });

    test('accepts valid Yemeni phone and dispatches', () async {
      when(() => mockLocalSource.insertHistoryRow(any())).thenAnswer((_) async {});
      when(() => mockDispatcher.send(
        phoneNumber: any(named: 'phoneNumber'),
        messageBody: any(named: 'messageBody'),
        channelType: any(named: 'channelType'),
        messageId: any(named: 'messageId'),
      )).thenAnswer((_) async => const SmsDispatchResult(success: true));
      when(() => mockLocalSource.updateHistoryRowStatus(
        any(),
        any(),
        sentAt: any(named: 'sentAt'),
      )).thenAnswer((_) async {});

      final result = await repository.sendSingleSms(
        messageBody: 'test',
        phoneNumber: '+967771234567',
      );
      expect(result.isRight(), true);
    });

    test('rejects invalid Saudi prefix phone', () async {
      final result = await repository.sendSingleSms(
        messageBody: 'test',
        phoneNumber: '+96650123456789',
      );
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message.contains('غير صالح'), true);
        },
        (_) => fail('expected failure'),
      );
    });
  });

  group('buildRecipientList', () {
    test('filters out invalid manual phones', () async {
      final result = await repository.buildRecipientList(
        manualPhones: [
          '+967771234567',
          '+966123',
          '+14155552671',
        ],
      );
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (resolution) {
          expect(resolution.resolved.length, 2);
          expect(resolution.resolved.any((r) => r.phoneNumber == '+967771234567'), true);
          expect(resolution.resolved.any((r) => r.phoneNumber == '+14155552671'), true);
        },
      );
    });

    test('allows all valid phones through', () async {
      final result = await repository.buildRecipientList(
        manualPhones: [
          '+967771234567',
          '+966501234567',
          '+14155552671',
        ],
      );
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (resolution) {
          expect(resolution.resolved.length, 3);
        },
      );
    });

    test('returns empty list when all manual phones are invalid', () async {
      final result = await repository.buildRecipientList(
        manualPhones: [
          '+966123',
          '+96712',
        ],
      );
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected success'),
        (resolution) {
          expect(resolution.resolved.length, 0);
        },
      );
    });
  });
}
