import 'package:flutter/material.dart';

import 'package:v2/widgets/appbar/profile_avatar.dart';

class MelodyGlassAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onProfileTap;

  const MelodyGlassAppBar({
    super.key,
    required this.title,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return SizedBox(
      height: 86,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          20,
          14,
          20,
          8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ),
            ProfileAvatar(
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}