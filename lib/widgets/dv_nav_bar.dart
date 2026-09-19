import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../app/theme.dart';

class _NavItem {
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.path});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}

const _navItems = [
  _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded, label: 'HOME', path: '/home'),
  _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'SQUAD', path: '/squad'),
  _NavItem(icon: Icons.headset_outlined, activeIcon: Icons.headset_rounded, label: 'ROOMS', path: '/rooms'),
  _NavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'MESSAGES', path: '/messages'),
  _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'PROFILE', path: '/profile'),
];

/// Custom gaming bottom navigation bar.
/// Feels like a piece of hardware — not the default Flutter BottomNavigationBar.
class DvNavBar extends StatelessWidget {
  const DvNavBar({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Dv.graphite,
        border: const Border(top: BorderSide(color: Dv.steel, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dv.s8, vertical: Dv.s4),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: _NavTile(
                  item: item,
                  isActive: isActive,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({required this.item, required this.isActive, required this.onTap});
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dv.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active indicator line
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: widget.isActive ? 20 : 0,
                margin: const EdgeInsets.only(bottom: Dv.s4),
                decoration: BoxDecoration(
                  color: Dv.green,
                  borderRadius: BorderRadius.circular(Dv.r100),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.icon,
                  key: ValueKey(widget.isActive),
                  color: widget.isActive ? Dv.green : Dv.slate,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.label,
                style: Dv.mono(
                  size: 9,
                  color: widget.isActive ? Dv.green : Dv.slate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shell scaffold wrapping the bottom-nav pages.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Dv.obsidian,
      body: navigationShell,
      bottomNavigationBar: DvNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
      ),
    );
  }
}
