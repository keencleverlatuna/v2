import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class GlassBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClosed;

  const GlassBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchClosed,
  });

  bool get isSearchActive =>
      currentIndex == 3;

  @override
  Widget build(BuildContext context) {
    return GlassTabBar.searchable(
      selectedIndex: isSearchActive
          ? 0
          : currentIndex,

      isSearchActive:
      isSearchActive,

      onTabSelected: (index) {
        onTap(index);
      },

      searchConfig:
      GlassSearchBarConfig(
        hintText:
        'Artists, Songs, Lyrics, and More',

        controller:
        searchController,

        onChanged:
        onSearchChanged,

        autoFocusOnExpand:
        true,

        showsCancelButton:
        true,

        cursorColor:
        CupertinoColors.systemIndigo,

        textColor:
        CupertinoColors.white,

        searchIconColor:
        CupertinoColors.systemGrey,

        onSearchToggle:
            (isActive) {
          if (isActive) {
            onTap(3);
          } else {
            onSearchClosed();
          }
        },

        onCancelTap: () {
          onSearchClosed();
        },
      ),

      barHeight: 68,
      searchBarHeight: 54,

      horizontalPadding: 14,
      verticalPadding: 12,

      spacing: 8,

      iconSize: 25,
      labelFontSize: 11,

      selectedIconColor:
      CupertinoColors.systemIndigo,

      selectedLabelColor:
      CupertinoColors.systemIndigo,

      unselectedIconColor:
      CupertinoColors.white,

      unselectedLabelColor:
      CupertinoColors.systemGrey,

      enableBlend: true,
      blendAmount: 10,

      tabs: const <GlassTab>[
        GlassTab(
          icon: Icon(
            CupertinoIcons.house_fill,
          ),
          label: 'Home',
        ),
        GlassTab(
          icon: Icon(
            CupertinoIcons
                .antenna_radiowaves_left_right,
          ),
          label: 'Radio',
        ),
        GlassTab(
          icon: Icon(
            CupertinoIcons.music_note_2,
          ),
          label: 'Library',
        ),
      ],
    );
  }
}

// ===========================================================
// COMPACT CIRCLE BUTTON
// ===========================================================


