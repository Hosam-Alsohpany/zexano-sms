import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/features/groups/domain/entities/group.dart';
import 'package:zexano_sms/features/groups/presentation/providers/groups_providers.dart';

class GroupListNotifier
    extends StateNotifier<AsyncValue<List<Group>>> {
  final Ref _ref;

  GroupListNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadGroups();
  }

  Future<void> loadGroups({String? query}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(groupsRepositoryProvider);
      if (query != null && query.isNotEmpty) {
        final result = await repo.searchGroups(query);
        return result.fold((f) => throw f, (g) => g);
      }
      final result = await repo.listGroups();
      return result.fold((f) => throw f, (g) => g);
    });
  }

  Future<void> refresh() async {
    final query = _ref.read(groupsSearchQueryProvider);
    await loadGroups(query: query);
  }

  Future<void> createGroup(Group group) async {
    final repo = _ref.read(groupsRepositoryProvider);
    final result = await repo.createGroup(group);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (created) {
        state.whenData((groups) {
          state = AsyncValue.data([...groups, created]);
        });
      },
    );
  }

  Future<void> deleteGroup(String id) async {
    final repo = _ref.read(groupsRepositoryProvider);
    final result = await repo.deleteGroup(id);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        state.whenData((groups) {
          state = AsyncValue.data(groups.where((g) => g.id != id).toList());
        });
      },
    );
  }
}
