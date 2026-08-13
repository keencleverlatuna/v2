import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:v2/providers/app/theme_provider.dart';
import 'package:v2/providers/library/favorites_provider.dart';
import 'package:v2/providers/library/recently_played_provider.dart';
import 'package:v2/providers/profile/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const Color _accent = Color(0xFFFF2D55);

  static const List<Color> _avatarColors = <Color>[
    Color(0xFF5C4B9B),
    Color(0xFFFF2D55),
    Color(0xFF007AFF),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFAF52DE),
    Color(0xFF00C7BE),
    Color(0xFF636366),
  ];

  bool _soundCheck = false;
  String _audioQuality = 'Standard';

  @override
  Widget build(BuildContext context) {
    final ProfileState profile = ref.watch(profileProvider);
    final favorites = ref.watch(favoritesProvider);
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final ThemeMode themeMode = ref.watch(themeProvider);
    final bool isDarkMode = themeMode == ThemeMode.dark;

    final Color avatarColor =
        _avatarColors[profile.avatarColorIndex % _avatarColors.length];

    return Scaffold(
      backgroundColor: _pageBackground(context),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _ProfileTopBar(onBack: () => context.pop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: <Widget>[
                  _ProfileHeader(
                    profile: profile,
                    avatarIcon: CupertinoIcons.person_fill,
                    avatarColor: avatarColor,
                    favoriteCount: favorites.length,
                    recentCount: recentlyPlayed.length,
                    onEditName: () => _showEditNameDialog(
                      context,
                      ref,
                      profile.name,
                    ),
                    onEditAvatar: () => _showAvatarCustomizer(
                      context,
                      ref,
                      profile,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('Appearance'),
                  const SizedBox(height: 9),
                  _IOSGroup(
                    children: <Widget>[
                      _SettingRow(
                        icon: CupertinoIcons.moon_fill,
                        iconColor: const Color(0xFF5856D6),
                        title: 'Dark Mode',
                        subtitle: isDarkMode ? 'On' : 'Off',
                        trailing: CupertinoSwitch(
                          value: isDarkMode,
                          activeTrackColor: _accent,
                          onChanged: (bool value) {
                            ref
                                .read(themeProvider.notifier)
                                .setDarkMode(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const _SectionLabel('Playback'),
                  const SizedBox(height: 9),
                  _IOSGroup(
                    children: <Widget>[
                      _SettingRow(
                        icon: CupertinoIcons.speaker_2_fill,
                        iconColor: const Color(0xFF007AFF),
                        title: 'Audio Quality',
                        subtitle: _audioQuality,
                        onTap: () => _showAudioQualityPicker(context),
                      ),
                      _SettingRow(
                        icon: CupertinoIcons.waveform,
                        iconColor: const Color(0xFF34C759),
                        title: 'Sound Check',
                        subtitle: 'Normalize playback volume',
                        trailing: CupertinoSwitch(
                          value: _soundCheck,
                          activeTrackColor: _accent,
                          onChanged: (bool value) {
                            setState(() => _soundCheck = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const _SectionLabel('V2'),
                  const SizedBox(height: 9),
                  _IOSGroup(
                    children: <Widget>[
                      _SettingRow(
                        icon: CupertinoIcons.info_circle_fill,
                        iconColor: const Color(0xFF8E8E93),
                        title: 'About V2',
                        subtitle: 'Version 1.0.0',
                        onTap: () => _showAboutDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Designed for your music.',
                      style: TextStyle(
                        color: _tertiaryText(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAudioQualityPicker(BuildContext context) async {
    final String? quality = await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Audio Quality'),
          message: const Text('Choose a playback quality.'),
          actions: <Widget>[
            for (final String option in <String>['Standard', 'High', 'Best'])
              CupertinoActionSheetAction(
                isDefaultAction: option == _audioQuality,
                onPressed: () => Navigator.of(sheetContext).pop(option),
                child: Text(option),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );

    if (quality != null && mounted) {
      setState(() => _audioQuality = quality);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('V2 Music Player'),
          content: const Text(
            'Version 1.0.0\n\nA simple music player with local importing, streaming, and background playback.',
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    String editedName = currentName;

    final String? result = await showCupertinoDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Edit Name'),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: CupertinoTextFormFieldRow(
              initialValue: currentName,
              autofocus: true,
              placeholder: 'Your name',
              textCapitalization: TextCapitalization.words,
              onChanged: (String value) => editedName = value,
              onFieldSubmitted: (String value) {
                final String cleanName = value.trim();
                if (cleanName.isNotEmpty) {
                  Navigator.of(dialogContext).pop(cleanName);
                }
              },
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final String cleanName = editedName.trim();
                if (cleanName.isNotEmpty) {
                  Navigator.of(dialogContext).pop(cleanName);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final String cleanName = result?.trim() ?? '';
    if (cleanName.isEmpty || cleanName == currentName) {
      return;
    }

    await ref.read(profileProvider.notifier).updateName(cleanName);
  }

  static Future<void> _showAvatarCustomizer(
    BuildContext context,
    WidgetRef ref,
    ProfileState profile,
  ) async {
    int selectedColor = profile.avatarColorIndex % _avatarColors.length;

    final int? result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: _groupFill(context),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 5,
                      decoration: BoxDecoration(
                        color: _tertiaryText(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Customize Profile',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: _avatarColors[selectedColor],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.person_fill,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Color',
                        style: TextStyle(
                          color: _secondaryText(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: List<Widget>.generate(
                        _avatarColors.length,
                        (int index) {
                          final bool selected = selectedColor == index;
                          return GestureDetector(
                            onTap: () =>
                                setModalState(() => selectedColor = index),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _avatarColors[index],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: selected
                                  ? const Icon(
                                      CupertinoIcons.check_mark,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(14),
                        onPressed: () {
                          Navigator.of(sheetContext).pop(selectedColor);
                        },
                        child: const Text('Save Profile Color'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    await ref.read(profileProvider.notifier).updateAvatar(
          iconIndex: 0,
          colorIndex: result,
        );
  }
}

class _ProfileTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _ProfileTopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minSize: 44,
            onPressed: onBack,
            child: Icon(
              CupertinoIcons.chevron_left,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
          ),
          Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 52),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileState profile;
  final IconData avatarIcon;
  final Color avatarColor;
  final int favoriteCount;
  final int recentCount;
  final VoidCallback onEditName;
  final VoidCallback onEditAvatar;

  const _ProfileHeader({
    required this.profile,
    required this.avatarIcon,
    required this.avatarColor,
    required this.favoriteCount,
    required this.recentCount,
    required this.onEditName,
    required this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF5E5CE6),
            Color(0xFFAF52DE),
            Color(0xFFFF375F),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFAF52DE).withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: onEditAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.40),
                          width: 2,
                        ),
                      ),
                      child: Icon(avatarIcon, color: Colors.white, size: 32),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFAF52DE),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.pencil,
                          color: _ProfileScreenState._accent,
                          size: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'V2 Listener',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onEditName,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              CupertinoIcons.pencil,
                              color: Colors.white,
                              size: 12,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: <Widget>[
                _HeaderStat(
                  icon: CupertinoIcons.heart_fill,
                  value: '$favoriteCount',
                  label: 'Favorites',
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                _HeaderStat(
                  icon: CupertinoIcons.clock_fill,
                  value: '$recentCount',
                  label: 'Recently Played',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: _secondaryText(context),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _IOSGroup extends StatelessWidget {
  final List<Widget> children;

  const _IOSGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> separated = <Widget>[];
    for (int index = 0; index < children.length; index++) {
      separated.add(children[index]);
      if (index < children.length - 1) {
        separated.add(
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 62,
            color: _divider(context),
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _groupFill(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _groupBorder(context), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: separated),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      minSize: 0,
      onPressed: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Icon(
                CupertinoIcons.chevron_forward,
                color: _tertiaryText(context),
                size: 16,
              ),
        ],
      ),
    );
  }
}

Color _pageBackground(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : const Color(0xFFF2F2F7);
}

Color _groupFill(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1C1C1E)
      : Colors.white;
}

Color _softFill(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2E)
      : const Color(0xFFEFEFF4);
}

Color _groupBorder(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.04);
}

Color _divider(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.10);
}

Color _secondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF98989D)
      : const Color(0xFF6C6C70);
}

Color _tertiaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF636366)
      : const Color(0xFFC7C7CC);
}
