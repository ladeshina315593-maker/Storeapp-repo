import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/themes/light_color.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final Function(int) onIconPresedCallback;

  CustomBottomNavigationBar({
    Key key,
    this.onIconPresedCallback,
  }) : super(key: key);

  @override
  _CustomBottomNavigationBarState createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState
    extends State<CustomBottomNavigationBar>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  AnimationController _xController;
  AnimationController _yController;

  @override
  void initState() {
    super.initState();

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

    Listenable.merge([
      _xController,
      _yController,
    ]).addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _xController.value =
        _indexToPosition(_selectedIndex) /
            MediaQuery.of(context).size.width;

    _yController.value = 1.0;
  }

  double _getButtonContainerWidth() {
    double width = MediaQuery.of(context).size.width;

    if (width > 400.0) {
      width = 400.0;
    }

    return width;
  }

  double _indexToPosition(int index) {
    const double buttonCount = 4.0;

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

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  Widget _icon(
    IconData icon,
    bool isSelected,
    int index,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
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
            width: isSelected ? 46 : 38,
            height: isSelected ? 46 : 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,

              color: isSelected
                  ? LightColor.grapePurple
                  : Colors.white.withOpacity(0.42),

              border: Border.all(
                color: Colors.white.withOpacity(0.85),
                width: 1.2,
              ),

              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? LightColor.grapePurple
                          .withOpacity(0.32)
                      : Colors.black.withOpacity(0.035),
                  blurRadius:
                      isSelected ? 15 : 8,
                  spreadRadius:
                      isSelected ? 1 : 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Opacity(
              opacity:
                  isSelected
                      ? _yController.value
                      : 1.0,
              child: Icon(
                icon,
                size:
                    isSelected ? 23 : 21,
                color: isSelected
                    ? Colors.white
                    : LightColor.darkText,
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
            color: Colors.white
                .withOpacity(0.58),

            borderRadius:
                BorderRadius.circular(30),

            border: Border.all(
              color: Colors.white
                  .withOpacity(0.82),
              width: 1.2,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 0,
                offset:
                    const Offset(0, 10),
              ),

              BoxShadow(
                color: LightColor
                    .grapePurple
                    .withOpacity(0.10),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePressed(int index) {
    if (_selectedIndex == index ||
        _xController.isAnimating) {
      return;
    }

    widget.onIconPresedCallback?.call(index);

    setState(() {
      _selectedIndex = index;
    });

    _yController.value = 1.0;

    _xController.animateTo(
      _indexToPosition(index) /
          MediaQuery.of(context).size.width,
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
  }

  @override
  Widget build(BuildContext context) {
    final Size appSize =
        MediaQuery.of(context).size;

    return Container(
      width: appSize.width,
      height: 78,
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Stack(
        children: [
          // Glass floating navigation background
          Positioned.fill(
            child: _buildGlassBackground(),
          ),

          // Navigation icons
          Positioned(
            left: 8,
            right: 8,
            top: 5,
            bottom: 5,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,
              children: <Widget>[
                _icon(
                  Icons.home_rounded,
                  _selectedIndex == 0,
                  0,
                ),

                _icon(
                  Icons.search_rounded,
                  _selectedIndex == 1,
                  1,
                ),

                _icon(
                  Icons.shopping_bag_rounded,
                  _selectedIndex == 2,
                  2,
                ),

                _icon(
                  Icons.favorite_border_rounded,
                  _selectedIndex == 3,
                  3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}