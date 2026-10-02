import 'package:flutter/material.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../domain/entities/group.dart';

class GroupListTile extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;
  final bool isSelected;

  const GroupListTile({
    super.key,
    required this.group,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        group.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Icon(
            Icons.people_outline,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            _memberCountLabel(context, group.memberCount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (group.description.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text('·'),
            ),
            Expanded(
              child: Text(
                group.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      isThreeLine: false,
      selected: isSelected,
      selectedTileColor:
          theme.colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      onTap: onTap,
    );
  }

  String _memberCountLabel(BuildContext context, int count) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      if (count == 0) return 'بدون أعضاء';
      if (count == 1) return 'عضو واحد';
      if (count == 2) return 'عضوان';
      return '$count أعضاء';
    }
    if (count == 0) return 'No members';
    if (count == 1) return '1 member';
    return '$count members';
  }
}
