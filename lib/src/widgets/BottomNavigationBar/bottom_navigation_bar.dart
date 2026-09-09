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
  // IMPORTANT:
  // - ONE floating glass container only
  // - NO circles around individual icons
  // - Cart uses a real shopping-cart icon
  // - Responsive across screen sizes
  // ============================================================

  static const Color pikkXBlack = Color(0xFF050505);
  static const Color pikkXWhite = Color(0xFFFFFFFF);
  static const Color pikkXGrey = Color(0xFF777777);

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
    Icons.home_rounded,
    Icons.shopping_cart_rounded,
    Icons.chat_bubble_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
  ];

  static const List<String> _labels = [
    'Home',
    'Cart',
    'Chat',
    'Favourite',
    'Profile',
  ];

  // ============================================================
  // SINGLE ICON ITEM
  //
  // There is intentionally NO BoxDecoration here.
  // No circle, no pill, no separate background.
  // ============================================================

  Widget _buildNavItem({
    required int index,
    required double iconSize,
  }) {
    final bool isSelected =
        widget.selectedIndex == index;

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
          borderRadius: BorderRadius.zero,
          child: AnimatedBuilder(
            animation: _selectionController,
            builder: (
              context,
              child,
            ) {
              final double t =
                  Curves.easeOutCubic.transform(
                _selectionController.value,
              );

              /*
               * Selected icons become slightly larger and settle
               * smoothly without receiving their own container.
               */
              final double scale = isSelected
                  ? 0.94 + (0.10 * t)
                  : 1.0;

              final double selectedOpacity =
                  isSelected
                      ? 0.72 + (0.28 * t)
                      : 1.0;

              return Center(
                child: Transform.translate(
                  offset: isSelected
                      ? Offset(
                          0,
                          -2.0 * t,
                        )
                      : Offset.zero,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: selectedOpacity,
                      child: Icon(
                        _icons[index],
                        size: isSelected
                            ? iconSize + 1
                            : iconSize,
                        color: isSelected
                            ? pikkXBlack
                            : pikkXGrey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GLASS BACKGROUND
  //
  // THIS is the ONE floating container.
  // ============================================================

  Widget _buildGlassBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: pikkXWhite.withOpacity(0.62),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: pikkXWhite.withOpacity(0.90),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: pikkXBlack.withOpacity(0.085),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 9),
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

    final double screenWidth =
        mediaQuery.size.width;

    /*
     * Responsive horizontal padding.
     *
     * The navigation never becomes ridiculously wide on tablets
     * and does not become cramped on smaller phones.
     */
    final double horizontalPadding =
        screenWidth < 360
            ? 8
            : screenWidth < 420
                ? 14
                : 24;

    final double bottomPadding =
        mediaQuery.padding.bottom > 0
            ? 4
            : 10;

    final double iconSize =
        screenWidth < 360
            ? 21
            : screenWidth < 420
                ? 22
                : 23;

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
            // ----------------------------------------------------
            // SINGLE FLOATING GLASS BAR
            // ----------------------------------------------------

            Positioned.fill(
              child: _buildGlassBackground(),
            ),

            // ----------------------------------------------------
            // ICONS
            // ----------------------------------------------------

            Positioned.fill(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(
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

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }
}