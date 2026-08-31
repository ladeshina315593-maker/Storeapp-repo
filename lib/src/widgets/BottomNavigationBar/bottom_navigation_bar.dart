import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _xController;
  late AnimationController _yController;

  int _previousIndex = 0;

  // HOME → CART → CHAT → FAVOURITE → PROFILE
  final List<IconData> _icons = const [
    Icons.home_rounded,
    Icons.shopping_bag_rounded,
    Icons.chat_bubble_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();

    _previousIndex = widget.selectedIndex;

    _xController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
      animationBehavior: AnimationBehavior.preserve,
    );

    _yController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      animationBehavior: AnimationBehavior.preserve,
    );

    _yController.value = 1.0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _xController.value =
        _indexToPosition(widget.selectedIndex) /
            MediaQuery.of(context).size.width;

    _yController.value = 1.0;
  }

  @override
  void didUpdateWidget(
    covariant CustomBottomNavigationBar oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex !=
        widget.selectedIndex) {
      _animateToIndex(widget.selectedIndex);
    }
  }

  double _indexToPosition(int index) {
    const double buttonCount = 5.0;

    final double appWidth =
        MediaQuery.of(context).size.width;

    final double buttonsWidth =
        _getButtonContainerWidth();

    final double startX =
        (appWidth - buttonsWidth) / 2;

    return startX +
        index.toDouble() *
            buttonsWidth /
            buttonCount +
        buttonsWidth /
            (buttonCount * 2.0);
  }

  double _getButtonContainerWidth() {
    double width =
        MediaQuery.of(context).size.width;

    if (width > 400.0) {
      width = 400.0;
    }

    return width;
  }

  void _animateToIndex(int index) {
    if (!mounted) return;

    if (_xController.isAnimating) {
      _xController.stop();
    }

    final double screenWidth =
        MediaQuery.of(context).size.width;

    final double target =
        _indexToPosition(index) /
            screenWidth;

    _yController.value = 1.0;

    _xController.animateTo(
      target,
      duration:
          const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
    );

    _yController.animateTo(
      0.0,
      duration:
          const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (!mounted) return;

        _yController.animateTo(
          1.0,
          duration:
              const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
        );
      },
    );

    _previousIndex = index;
  }

  void _handlePressed(int index) {
    if (index == widget.selectedIndex) {
      return;
    }

    if (_xController.isAnimating) {
      _xController.stop();
    }

    // MainPage owns the real navigation state.
    widget.onIconPressedCallback(index);

    _animateToIndex(index);
  }

  Widget _icon(
    IconData icon,
    bool isSelected,
    int index,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius:
            BorderRadius.circular(40),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          _handlePressed(index);
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: isSelected
              ? Alignment.topCenter
              : Alignment.center,
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: isSelected ? 44 : 38,
            height: isSelected ? 44 : 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              // pikkX BLACK when selected
              color: isSelected
                  ? const Color(0xFF050505)
                  : Colors.white.withOpacity(0.38),

              border: Border.all(
                color:
                    Colors.white.withOpacity(0.85),
                width: 1.2,
              ),

              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFF050505)
                          .withOpacity(0.30)
                      : Colors.black.withOpacity(0.04),
                  blurRadius:
                      isSelected ? 14 : 8,
                  spreadRadius:
                      isSelected ? 1 : 0,
                  offset:
                      const Offset(0, 5),
                ),
              ],
            ),
            child: Opacity(
              opacity: isSelected
                  ? _yController.value
                  : 1.0,
              child: Icon(
                icon,
                size: isSelected ? 22 : 20,
                color: isSelected
                    ? Colors.white
                    : const Color(0xFF050505),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackground() {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
        ),
        child: Container(
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.58),

            borderRadius:
                BorderRadius.circular(30),

            border: Border.all(
              color:
                  Colors.white.withOpacity(0.82),
              width: 1.2,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset:
                    const Offset(0, 10),
              ),

              // BLACK glass shadow instead of purple
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.06),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width =
        MediaQuery.of(context).size.width;

    return Container(
      width: width,
      height: 76,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 10,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _buildGlassBackground(),
          ),

          Positioned(
            left: 8,
            right: 8,
            top: 5,
            bottom: 5,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: [
                _icon(
                  _icons[0],
                  widget.selectedIndex == 0,
                  0,
                ),
                _icon(
                  _icons[1],
                  widget.selectedIndex == 1,
                  1,
                ),
                _icon(
                  _icons[2],
                  widget.selectedIndex == 2,
                  2,
                ),
                _icon(
                  _icons[3],
                  widget.selectedIndex == 3,
                  3,
                ),
                _icon(
                  _icons[4],
                  widget.selectedIndex == 4,
                  4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }
}