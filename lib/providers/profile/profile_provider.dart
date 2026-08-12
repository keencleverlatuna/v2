import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileState {
  final String name;
  final int avatarIconIndex;
  final int avatarColorIndex;

  const ProfileState({
    required this.name,
    required this.avatarIconIndex,
    required this.avatarColorIndex,
  });

  ProfileState copyWith({
    String? name,
    int? avatarIconIndex,
    int? avatarColorIndex,
  }) {
    return ProfileState(
      name: name ?? this.name,
      avatarIconIndex:
      avatarIconIndex ?? this.avatarIconIndex,
      avatarColorIndex:
      avatarColorIndex ?? this.avatarColorIndex,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  static const String _nameKey =
      'melody_profile_name';

  static const String _avatarIconKey =
      'melody_profile_avatar_icon';

  static const String _avatarColorKey =
      'melody_profile_avatar_color';

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;

  @override
  ProfileState build() {
    _loadFuture = _loadProfile();

    return const ProfileState(
      name: 'Katherine',
      avatarIconIndex: 0,
      avatarColorIndex: 0,
    );
  }

  Future<void> _loadProfile() async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      _preferences = prefs;

      final String? savedName =
      prefs.getString(_nameKey);

      final int savedIcon =
          prefs.getInt(_avatarIconKey) ?? 0;

      final int savedColor =
          prefs.getInt(_avatarColorKey) ?? 0;

      state = state.copyWith(
        name: savedName != null &&
            savedName.trim().isNotEmpty
            ? savedName.trim()
            : state.name,
        avatarIconIndex: savedIcon,
        avatarColorIndex: savedColor,
      );
    } catch (_) {
      // Keep default profile values.
    }
  }

  Future<void> _ensureLoaded() async {
    await (_loadFuture ??= _loadProfile());
  }

  Future<void> updateName(
      String newName,
      ) async {
    await _ensureLoaded();

    final String cleanName =
    newName.trim();

    if (cleanName.isEmpty) {
      return;
    }

    state = state.copyWith(
      name: cleanName,
    );

    final prefs =
        _preferences ??
            await SharedPreferences.getInstance();

    _preferences = prefs;

    await prefs.setString(
      _nameKey,
      cleanName,
    );
  }

  Future<void> updateAvatarIcon(
      int index,
      ) async {
    await _ensureLoaded();

    state = state.copyWith(
      avatarIconIndex: index,
    );

    final prefs =
        _preferences ??
            await SharedPreferences.getInstance();

    _preferences = prefs;

    await prefs.setInt(
      _avatarIconKey,
      index,
    );
  }

  Future<void> updateAvatarColor(
      int index,
      ) async {
    await _ensureLoaded();

    state = state.copyWith(
      avatarColorIndex: index,
    );

    final prefs =
        _preferences ??
            await SharedPreferences.getInstance();

    _preferences = prefs;

    await prefs.setInt(
      _avatarColorKey,
      index,
    );
  }

  Future<void> updateAvatar({
    required int iconIndex,
    required int colorIndex,
  }) async {
    await _ensureLoaded();

    state = state.copyWith(
      avatarIconIndex: iconIndex,
      avatarColorIndex: colorIndex,
    );

    final prefs =
        _preferences ??
            await SharedPreferences.getInstance();

    _preferences = prefs;

    await Future.wait([
      prefs.setInt(
        _avatarIconKey,
        iconIndex,
      ),
      prefs.setInt(
        _avatarColorKey,
        colorIndex,
      ),
    ]);
  }
}

final profileProvider =
NotifierProvider<
    ProfileNotifier,
    ProfileState>(
  ProfileNotifier.new,
);