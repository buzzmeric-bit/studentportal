import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BubbleNavBar extends StatefulWidget {
  final int currentIndex;
  
  const BubbleNavBar({
    super.key,
    this.currentIndex = 0,
  });

  @override
  State<BubbleNavBar> createState() => _BubbleNavBarState();
}

class _BubbleNavBarState extends State<BubbleNavBar> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<_NavItem> _items = const [
    _NavItem(
      icon: Icons.home_rounded,
      label: 'Accueil',
      route: '/',
    ),
    _NavItem(
      icon: Icons.mail_rounded,
      label: 'Messages',
      route: '/messages',
      badgeCount: 3,
    ),
    _NavItem(
      icon: Icons.notifications_rounded,
      label: 'Notifications',
      route: '/notifications',
      badgeCount: 1,
    ),
    _NavItem(
      icon: Icons.bar_chart_rounded,
      label: 'Stats',
      route: '/stats',
    ),
    _NavItem(
      icon: Icons.auto_stories_rounded,
      label: 'Cours',
      route: '/courses',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(BubbleNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = widget.currentIndex;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
      
      // Navigate using go to replace the current route
      context.go(_items[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Animated Glowing Bubble
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final itemWidth = screenWidth / _items.length;
                    final bubbleOffset = (itemWidth * _selectedIndex) + (itemWidth / 2) - 28;
                    
                    return Positioned(
                      left: bubbleOffset,
                      top: 12,
                      child: Transform.scale(
                        scale: _animation.value,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF8B5CF6),
                                Color(0xFF6366F1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // Nav Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isSelected = _selectedIndex == index;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onItemTapped(index),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: isSelected ? 26 : 23,
                                ),
                                if (item.badgeCount != null && item.badgeCount! > 0)
                                  Positioned(
                                    right: -8,
                                    top: -8,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF43F5E),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        item.badgeCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final int? badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badgeCount,
  });
}
