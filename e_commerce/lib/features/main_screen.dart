import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:e_commerce/features/activity/views/activity_screen.dart';
import 'package:e_commerce/features/wishlist/views/wishlist_screen.dart';
import 'package:e_commerce/features/cart/views/cart_screen.dart';
import 'package:e_commerce/features/profile/views/profile_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  
  // Pre-build all screens
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    
    // Initialize all screens once to avoid recreation
    _screens = [
      ActivityScreen(),
      WishlistScreen(),
      CartScreen(),
      const Center(child: Text('Mesajlar sayfası yapım aşamasında')),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      // Use IndexedStack to preserve state across tab switches
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: l10n.wishlist,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: l10n.orders,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: l10n.messages,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: l10n.profile,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
} 