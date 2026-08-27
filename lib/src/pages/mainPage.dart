import 'package:flutter/material.dart';
import 'package:flutter_ecommerce_app/src/pages/home_page.dart';
import 'package:flutter_ecommerce_app/src/pages/shopping_cart_page.dart';
import 'package:flutter_ecommerce_app/src/themes/light_color.dart';
import 'package:flutter_ecommerce_app/src/themes/theme.dart';
import 'package:flutter_ecommerce_app/src/widgets/BottomNavigationBar/bottom_navigation_bar.dart';
import 'package:flutter_ecommerce_app/src/widgets/title_text.dart';
import 'package:flutter_ecommerce_app/src/widgets/extentions.dart';

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool isHomePageSelected = true;

  Widget _glassIcon(
    IconData icon, {
    Color iconColor,
    VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.85),
              width: 1,
            ),
            boxShadow: AppTheme.shadow,
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppTheme.darkText,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: AppTheme.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _glassIcon(
            Icons.menu_rounded,
            iconColor: AppTheme.darkText,
            onPressed: () {
              // Menu action can be connected when the menu is ready.
            },
          ),

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Profile action can be connected to the profile page.
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 46,
                width: 46,
                padding: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.glassWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: 1,
                  ),
                  boxShadow: AppTheme.shadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.asset(
                    "assets/user.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return Container(
      margin: AppTheme.padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TitleText(
                text: isHomePageSelected ? 'Our' : 'Shopping',
                fontSize: 27,
                fontWeight: FontWeight.w400,
                color: AppTheme.darkText,
              ),
              TitleText(
                text: isHomePageSelected ? 'Products' : 'Cart',
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: AppTheme.darkText,
              ),
            ],
          ),

          Spacer(),

          if (!isHomePageSelected)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _showClearCartDialog();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.glassWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.85),
                    ),
                    boxShadow: AppTheme.shadow,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.grapePurple,
                    size: 21,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.96),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Clear cart?',
            style: TextStyle(
              color: AppTheme.darkText,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This will remove all items from your cart.',
            style: TextStyle(
              color: AppTheme.mutedText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.mutedText,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cart cleared'),
                    backgroundColor: AppTheme.grapePurple,
                  ),
                );
              },
              child: Text(
                'Clear',
                style: TextStyle(
                  color: AppTheme.grapePurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void onBottomIconPressed(int index) {
    if (index == 0 || index == 1) {
      setState(() {
        isHomePageSelected = true;
      });
    } else {
      setState(() {
        isHomePageSelected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grapeLightPurple,

      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.grapeLightPurple,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _appBar(),

                  _title(),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInToLinear,
                      switchOutCurve: Curves.easeOutBack,
                      child: isHomePageSelected
                          ? MyHomePage()
                          : Align(
                              alignment: Alignment.topCenter,
                              child: ShoppingCartPage(),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: CustomBottomNavigationBar(
                onIconPresedCallback:
                    onBottomIconPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}