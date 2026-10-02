import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/groups/domain/repositories/groups_repository.dart';

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return sl<GroupsRepository>();
});

final groupsSearchQueryProvider = StateProvider<String>((ref) => '');
