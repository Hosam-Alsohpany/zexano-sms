import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/group.dart';
import '../controllers/group_list_notifier.dart';
import '../providers/groups_providers.dart';
import '../widgets/group_list_tile.dart';

final groupListProvider = StateNotifierProvider<GroupListNotifier,
    AsyncValue<List<Group>>>(
  (ref) => GroupListNotifier(ref),
);

class GroupsHomeView extends ConsumerStatefulWidget {
  const GroupsHomeView({super.key});

  @override
  ConsumerState<GroupsHomeView> createState() => _GroupsHomeViewState();
}

class _GroupsHomeViewState extends ConsumerState<GroupsHomeView> {
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(groupsSearchQueryProvider.notifier).state = value;
    ref.read(groupListProvider.notifier).loadGroups(query: value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(groupListProvider);
    final searchQuery = ref.watch(groupsSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchGroups,
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: _onSearchChanged,
              )
            : Text(l10n.groups),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: l10n.search,
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _onSearchChanged('');
                }
              });
            },
          ),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.errorOccurred,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: l10n.retry,
                  onPressed: () =>
                      ref.read(groupListProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
        data: (groups) {
          if (_showSearch && searchQuery.isNotEmpty && groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64,
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.4)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.noResults,
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }

          if (groups.isEmpty) {
            return EmptyStateView(
              icon: Icons.group_outlined,
              title: l10n.noGroups,
              subtitle: l10n.addGroupSubtitle,
              actionLabel: l10n.addGroup,
              onAction: () => context.push('/groups/new'),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(groupListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return GroupListTile(
                  group: group,
                  onTap: () => context.push('/groups/${group.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/groups/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
