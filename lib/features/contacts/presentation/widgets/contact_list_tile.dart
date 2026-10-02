import 'package:flutter/material.dart';
import '../../../../config/design_system/app_spacing.dart';
import '../../../../shared/widgets/custom_avatar.dart';
import '../../../contacts/domain/entities/contact.dart';

class ContactListTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final bool isSelected;
  final bool isSelectionMode;

  const ContactListTile({
    super.key,
    required this.contact,
    this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: isSelected
          ? CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 20),
            )
          : CustomAvatar(
              firstName: contact.firstName,
              lastName: contact.lastName,
              size: 44,
            ),
      title: Text(
        contact.fullName,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: contact.normalizedPhone.isNotEmpty
          ? Text(
              contact.normalizedPhone,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
            )
          : null,
      trailing: isSelectionMode
          ? null
          : IconButton(
              icon: Icon(
                contact.isFavorite ? Icons.star : Icons.star_border,
                color: contact.isFavorite
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
              onPressed: onFavoriteToggle,
              visualDensity: VisualDensity.compact,
            ),
      isThreeLine: false,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
