import 'dart:ui';

import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onIconPressedCallback,
  });

  /// The tab currently displayed by MainPage.
  final int selectedIndex;

  /// Tells MainPage which tab the user selected.
  final ValueChanged<int> onIconPressedCallback;

  @override
  State<CustomBottomNavigationBar> createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState
    extends State<CustomBottomNavigationBar>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // PIKKX BOTTOM NAVIGATION
  //
  // Home → Cart → Chat → Favourite → Profile
  //
  // DESIGN:
  // - ONE floating glass container
  // - Icon above label
  // - No circles around individual icons
  // - Subtle selected highlight
  // - Black / white PikkX glass style
  // - Responsive across screen sizes
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);

  late final AnimationController _selectionController;

  @override
  void initState() {
    super.initState();

    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(
    covariant CustomBottomNavigationBar oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _playSelectionAnimation();
    }
  }

  // ============================================================
  // SELECTION ANIMATION
  // ============================================================

  void _playSelectionAnimation() {
    if (!mounted) return;

    _selectionController.forward(from: 0.0);
  }

  void _handlePressed(int index) {
    if (index == widget.selectedIndex) {
      return;
    }

    widget.onIconPressedCallback(index);

    _playSelectionAnimation();
  }

  // ============================================================
  // TAB DATA
  // ============================================================

  static const List<IconData> _icons = [
    Icons.home_outlined,
    Icons.shopping_cart_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.favorite_border_rounded,
    Icons.person_outline_rounded,
  ];

  static const List<String> _labels = [
    'Home',
    'Cart',
    'Chat',
    'Favourite',
    'Profile',
  ];

  // ============================================================
  // NAVIGATION ITEM
  //
  // Icon sits above the label.
  // No individual circles.
  // Selected item gets a subtle rounded highlight.
  // ============================================================

  Widget _buildNavItem({
    required int index,
    required double iconSize,
  }) {
    final bool isSelected = widget.selectedIndex == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: _labels[index],
        child: InkWell(
          onTap: () => _handlePressed(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? pikkXBlack.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected
                        ? _getSelectedIcon(index)
                        : _icons[index],
                    size: index == 2
                        ? iconSize + 1
                        : iconSize,
                    color: isSelected
                        ? pikkXBlack
                        : pikkXBlack.withOpacity(0.48),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    _labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? pikkXBlack
                          : pikkXBlack.withOpacity(0.48),
                      fontSize: 10.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED ICONS
  // ============================================================

  IconData _getSelectedIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;

      case 1:
        return Icons.shopping_cart_rounded;

      case 2:
        return Icons.chat_bubble_rounded;

      case 3:
        return Icons.favorite_rounded;

      case 4:
        return Icons.person_rounded;

      default:
        return _icons[index];
    }
  }

  // ============================================================
  // GLASS BACKGROUND
  //
  // ONE floating glass container.
  // ============================================================

  Widget _buildGlassBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.68),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.90),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.055),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final double screenWidth = mediaQuery.size.width;

    // ----------------------------------------------------------
    // RESPONSIVE HORIZONTAL PADDING
    // ----------------------------------------------------------

    final double horizontalPadding =
        screenWidth < 360
            ? 8
            : screenWidth < 420
                ? 14
                : 24;

    // ----------------------------------------------------------
    // BOTTOM SAFE AREA
    // ----------------------------------------------------------

    final double bottomPadding =
        mediaQuery.padding.bottom > 0
            ? 4
            : 10;

    // ----------------------------------------------------------
    // RESPONSIVE ICON SIZE
    // ----------------------------------------------------------

    final double iconSize =
        screenWidth < 360
            ? 21
            : screenWidth < 420
                ? 22
                : 23;

    // ----------------------------------------------------------
    // RESPONSIVE NAVIGATION HEIGHT
    // ----------------------------------------------------------

    final double navHeight =
        screenWidth < 360
            ? 66
            : 70;

    return SizedBox(
      width: screenWidth,
      height: navHeight + bottomPadding,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          bottomPadding,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ==================================================
            // SINGLE FLOATING GLASS BAR
            // ==================================================

            Positioned.fill(
              child: _buildGlassBackground(),
            ),

            // ==================================================
            // NAVIGATION ITEMS
            // ==================================================

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                ),
                child: Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      iconSize: iconSize,
                    ),

                    _buildNavItem(
                      index: 1,
                      iconSize: iconSize,
                    ),

                    _buildNavItem(
                      index: 2,
                      iconSize: iconSize,
                    ),

                    _buildNavItem(
                      index: 3,
                      iconSize: iconSize,
                    ),

                    _buildNavItem(
                      index: 4,
                      iconSize: iconSize,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }
}