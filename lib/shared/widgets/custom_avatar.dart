import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomAvatar({
    super.key,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
  });

  String get _initials {
    final firstTrim = (firstName ?? '').trim();
    final lastTrim = (lastName ?? '').trim();
    final first =
        firstTrim.isNotEmpty ? String.fromCharCode(firstTrim.runes.first) : '';
    final last =
        lastTrim.isNotEmpty ? String.fromCharCode(lastTrim.runes.first) : '';
    if (first.isEmpty && last.isEmpty) return '?';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(photoUrl!),
        onBackgroundImageError: (_, __) => _buildFallback(theme),
      );
    }

    return _buildFallback(theme);
  }

  Widget _buildFallback(ThemeData theme) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor:
          backgroundColor ?? theme.colorScheme.primaryContainer,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: textColor ?? theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
