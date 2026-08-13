import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:v2/screens/home/home_screen.dart';
import 'package:v2/screens/library/library_screen.dart';
import 'package:v2/screens/radio/radio_screen.dart';
import 'package:v2/screens/search/search_screen.dart';

import 'package:v2/widgets/appbar/glass_appbar.dart';
import 'package:v2/widgets/navigation/glass_bottom_navigation.dart';
import 'package:v2/widgets/player/mini_player.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
  });

  @override
  State<MainShell> createState() =>
      _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;

  int _lastNonSearchIndex = 0;

  // =========================================================
  // SCROLL CONTROLLERS
  // =========================================================

  final ScrollController _homeScrollController =
  ScrollController();

  final ScrollController _radioScrollController =
  ScrollController();

  final ScrollController _libraryScrollController =
  ScrollController();

  final List<bool> _compactStates = <bool>[
    false,
    false,
    false,
  ];

  // =========================================================
  // SEARCH
  // =========================================================

  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  static const List<String> _titles = <String>[
    'Home',
    'Radio',
    'Library',
    'Search',
  ];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _homeScrollController.addListener(
      _handleHomeScroll,
    );

    _radioScrollController.addListener(
      _handleRadioScroll,
    );

    _libraryScrollController.addListener(
      _handleLibraryScroll,
    );
  }

  // =========================================================
  // SCROLL HANDLERS
  // =========================================================

  void _handleHomeScroll() {
    _updateCompactState(
      index: 0,
      controller: _homeScrollController,
    );
  }

  void _handleRadioScroll() {
    _updateCompactState(
      index: 1,
      controller: _radioScrollController,
    );
  }

  void _handleLibraryScroll() {
    _updateCompactState(
      index: 2,
      controller: _libraryScrollController,
    );
  }

  // =========================================================
  // COMPACT STATE
  // =========================================================

  void _updateCompactState({
    required int index,
    required ScrollController controller,
  }) {
    if (!controller.hasClients) {
      return;
    }

    final bool shouldCompact =
        controller.offset > 50;

    if (_compactStates[index] == shouldCompact) {
      return;
    }

    _compactStates[index] = shouldCompact;

    if (!mounted ||
        selectedIndex != index) {
      return;
    }

    setState(() {});
  }

  bool get _isCurrentTabCompact {
    if (selectedIndex < 0 ||
        selectedIndex > 2) {
      return false;
    }

    return _compactStates[selectedIndex];
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _homeScrollController.removeListener(
      _handleHomeScroll,
    );

    _radioScrollController.removeListener(
      _handleRadioScroll,
    );

    _libraryScrollController.removeListener(
      _handleLibraryScroll,
    );

    _homeScrollController.dispose();
    _radioScrollController.dispose();
    _libraryScrollController.dispose();

    _searchController.dispose();

    super.dispose();
  }

  // =========================================================
  // TAB
  // =========================================================

  void _selectTab(
      int index,
      ) {
    if (index == selectedIndex) {
      return;
    }

    if (index == 3 &&
        selectedIndex >= 0 &&
        selectedIndex <= 2) {
      _lastNonSearchIndex =
          selectedIndex;
    }

    if (selectedIndex == 3 &&
        index != 3) {
      _clearSearch();
    }

    setState(() {
      selectedIndex = index;

      if (index >= 0 &&
          index <= 2) {
        _lastNonSearchIndex =
            index;
      }
    });
  }

  // =========================================================
  // SEARCH
  // =========================================================

  void _clearSearch() {
    _searchController.clear();

    _searchQuery = '';

    FocusManager.instance.primaryFocus
        ?.unfocus();
  }

  void _onSearchChanged(
      String value,
      ) {
    if (!mounted ||
        _searchQuery == value) {
      return;
    }

    setState(() {
      _searchQuery = value;
    });
  }

  void _useRecentSearch(
      String value,
      ) {
    final String cleanValue =
    value.trim();

    if (cleanValue.isEmpty) {
      return;
    }

    if (selectedIndex >= 0 &&
        selectedIndex <= 2) {
      _lastNonSearchIndex =
          selectedIndex;
    }

    _searchController.value =
        TextEditingValue(
          text: cleanValue,
          selection:
          TextSelection.collapsed(
            offset: cleanValue.length,
          ),
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _searchQuery = cleanValue;
      selectedIndex = 3;
    });
  }

  void _closeSearch() {
    _clearSearch();

    if (!mounted) {
      return;
    }

    setState(() {
      selectedIndex =
          _lastNonSearchIndex;
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final bool compact =
        _isCurrentTabCompact;

    final bool searchActive =
        selectedIndex == 3;

    final bool isDarkMode =
        Theme.of(context).brightness ==
            Brightness.dark;

    final List<Widget> pages =
    <Widget>[
      HomeScreen(
        scrollController:
        _homeScrollController,
      ),
      RadioScreen(
        scrollController:
        _radioScrollController,
      ),
      LibraryScreen(
        scrollController:
        _libraryScrollController,
      ),
      SearchScreen(
        query:
        _searchQuery,
        onRecentSearchSelected:
        _useRecentSearch,
      ),
    ];

    return GlassScaffold(
      edgeFade: false,
      extendBody: true,

      // =====================================================
      // BACKGROUND
      // =====================================================

      background: AnimatedContainer(
        duration: const Duration(
          milliseconds: 300,
        ),
        curve:
        Curves.easeInOut,
        decoration: BoxDecoration(
          gradient:
          LinearGradient(
            begin:
            Alignment.topCenter,
            end:
            Alignment.bottomCenter,
            colors: isDarkMode
                ? const <Color>[
              Color(
                0xFF090709,
              ),
              Color(
                0xFF000000,
              ),
            ]
                : const <Color>[
              Color(
                0xFFF7F7FA,
              ),
              Color(
                0xFFFFFFFF,
              ),
            ],
          ),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            MelodyGlassAppBar(
              title:
              _titles[selectedIndex],
              onProfileTap: () {
                context.push(
                  '/profile',
                );
              },
            ),

            Expanded(
              child:
              IndexedStack(
                index:
                selectedIndex,
                children:
                pages,
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // BOTTOM AREA
      // =====================================================

      bottomBar:
      AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 320,
        ),
        curve:
        Curves.easeOutCubic,

        height: searchActive
            ? 90
            : compact
            ? 90
            : 170,

        child: Stack(
          clipBehavior:
          Clip.none,
          children: <Widget>[
            // =================================================
            // NORMAL MINI PLAYER
            // =================================================

            AnimatedPositioned(
              duration:
              const Duration(
                milliseconds: 320,
              ),
              curve:
              Curves.easeOutCubic,
              left: 14,
              right: 14,

              bottom:
              compact ||
                  searchActive
                  ? 10
                  : 88,

              child:
              AnimatedOpacity(
                duration:
                const Duration(
                  milliseconds: 180,
                ),
                curve:
                Curves.easeOut,

                opacity:
                compact ||
                    searchActive
                    ? 0
                    : 1,

                child:
                IgnorePointer(
                  ignoring:
                  compact ||
                      searchActive,

                  child:
                  const MiniPlayer(
                    compact: false,
                  ),
                ),
              ),
            ),

            // =================================================
            // NORMAL NAVIGATION
            // =================================================

            AnimatedPositioned(
              duration:
              const Duration(
                milliseconds: 320,
              ),
              curve:
              Curves.easeOutCubic,

              left: 0,
              right: 0,

              bottom:
              compact
                  ? -90
                  : 0,

              child:
              AnimatedOpacity(
                duration:
                const Duration(
                  milliseconds: 180,
                ),
                curve:
                Curves.easeOut,

                opacity:
                compact
                    ? 0
                    : 1,

                child:
                IgnorePointer(
                  ignoring:
                  compact,

                  child:
                  GlassBottomNavigation(
                    currentIndex:
                    selectedIndex,
                    onTap:
                    _selectTab,
                    searchController:
                    _searchController,
                    onSearchChanged:
                    _onSearchChanged,
                    onSearchClosed:
                    _closeSearch,
                  ),
                ),
              ),
            ),

            // =================================================
            // COMPACT CONTROLS
            //
            // ○ Home
            //   7px
            // ─ Mini Player ─
            //   7px
            // ○ Search
            // =================================================

            AnimatedPositioned(
              duration:
              const Duration(
                milliseconds: 320,
              ),
              curve:
              Curves.easeOutCubic,

              left:
              compact
                  ? 14
                  : 80,

              right:
              compact
                  ? 14
                  : 80,

              bottom:
              compact
                  ? 12
                  : -90,

              child:
              AnimatedOpacity(
                duration:
                const Duration(
                  milliseconds: 220,
                ),
                curve:
                Curves.easeIn,

                opacity:
                compact
                    ? 1
                    : 0,

                child:
                IgnorePointer(
                  ignoring:
                  !compact,

                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .center,
                    children:
                    <Widget>[
                      // =====================================
                      // HOME CIRCLE
                      // =====================================

                      CompactGlassButton(
                        icon:
                        CupertinoIcons
                            .house_fill,

                        selected:
                        selectedIndex ==
                            0,

                        onTap: () {
                          _selectTab(
                            0,
                          );
                        },
                      ),

                      // =====================================
                      // GAP
                      // =====================================

                      const SizedBox(
                        width: 7,
                      ),

                      // =====================================
                      // MINI PLAYER PILL
                      // =====================================

                      const Expanded(
                        child:
                        MiniPlayer(
                          compact: true,
                        ),
                      ),

                      // =====================================
                      // GAP
                      // =====================================

                      const SizedBox(
                        width: 7,
                      ),

                      // =====================================
                      // SEARCH CIRCLE
                      // =====================================

                      CompactGlassButton(
                        icon:
                        CupertinoIcons
                            .search,

                        selected:
                        selectedIndex ==
                            3,

                        onTap: () {
                          _selectTab(
                            3,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// COMPACT GLASS BUTTON
// ===========================================================

// ===========================================================
// PREMIUM COMPACT GLASS BUTTON
// ===========================================================

class CompactGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  const CompactGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return GestureDetector(
      behavior:
      HitTestBehavior.opaque,

      onTap: onTap,

      child: SizedBox.square(
        dimension: 62,

        child: ClipRRect(
          borderRadius:
          BorderRadius.circular(
            31,
          ),

          child:
          GlassContainer(
            child:
            AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 220,
              ),

              curve:
              Curves.easeOutCubic,

              width: 62,
              height: 62,

              alignment:
              Alignment.center,

              decoration:
              BoxDecoration(
                shape:
                BoxShape.circle,

                // Transparent premium
                // internal highlight.
                gradient:
                LinearGradient(
                  begin:
                  Alignment.topLeft,
                  end:
                  Alignment.bottomRight,

                  colors: isDark
                      ? <Color>[
                    Colors.white
                        .withValues(
                      alpha: 0.11,
                    ),
                    Colors.white
                        .withValues(
                      alpha: 0.025,
                    ),
                  ]
                      : <Color>[
                    Colors.white
                        .withValues(
                      alpha: 0.34,
                    ),
                    Colors.white
                        .withValues(
                      alpha: 0.10,
                    ),
                  ],
                ),

                border:
                Border.all(
                  color:
                  colors.onSurface
                      .withValues(
                    alpha:
                    isDark
                        ? 0.12
                        : 0.08,
                  ),
                  width: 0.8,
                ),
              ),

              child:
              AnimatedScale(
                duration:
                const Duration(
                  milliseconds: 180,
                ),
                curve:
                Curves.easeOutCubic,

                scale:
                selected
                    ? 1.07
                    : 1.0,

                child:
                AnimatedSwitcher(
                  duration:
                  const Duration(
                    milliseconds: 180,
                  ),

                  child: Icon(
                    icon,

                    key:
                    ValueKey<bool>(
                      selected,
                    ),

                    size: 27,

                    color: selected
                        ? const Color(
                      0xFFFF2D55,
                    )
                        : colors
                        .onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}