import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v2/providers/profile/profile_provider.dart';

class ProfileAvatar extends ConsumerWidget {
  final VoidCallback? onTap;
  final double size;

  const ProfileAvatar({
    super.key,
    this.onTap,
    this.size = 38,
  });

  static const List<IconData> _avatarIcons = [
    CupertinoIcons.person_fill,
    CupertinoIcons.music_note_2,
    CupertinoIcons.headphones,
    CupertinoIcons.heart_fill,
    CupertinoIcons.star_fill,
    CupertinoIcons.bolt_fill,
    CupertinoIcons.game_controller_solid,
    CupertinoIcons.smiley_fill,
  ];

  static const List<Color> _avatarColors = [
    Color(0xFF5C4B9B),
    Color(0xFFFF2D55),
    Color(0xFF007AFF),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
    Color(0xFF00C7BE),
    Color(0xFF636366),
  ];

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final ProfileState profile =
    ref.watch(profileProvider);

    final int iconIndex =
        profile.avatarIconIndex %
            _avatarIcons.length;

    final int colorIndex =
        profile.avatarColorIndex %
            _avatarColors.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 250,
        ),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _avatarColors[colorIndex],
        ),
        child: Icon(
          _avatarIcons[iconIndex],
          color: Colors.white,
          size: size * 0.46,
        ),
      ),
    );
  }
}