import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/features/sms/domain/entities/sms_message.dart';
import 'package:zexano_sms/features/sms/presentation/providers/sms_providers.dart';

class SmsListNotifier
    extends StateNotifier<AsyncValue<List<SmsMessage>>> {
  final Ref _ref;

  SmsListNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(smsRepositoryProvider);
      final result = await repo.listSmsHistory();
      return result.fold((f) => throw f, (list) => list);
    });
  }

  Future<void> refresh() async {
    await loadHistory();
  }

  Future<void> deleteMessage(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(smsRepositoryProvider);
      final result = await repo.calculateBatchResult(id);
      await result.fold((f) async => throw f, (_) async {});
      final listResult = await repo.listSmsHistory();
      return listResult.fold((f) => throw f, (list) => list);
    });
  }
}
