import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_shadows.dart';

class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class AnimatedBottomNavigation extends StatelessWidget {
  const AnimatedBottomNavigation({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final List<AppNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: SizedBox(
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              top: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.darkNav,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.soft,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final center = index == 2;
                if (center) {
                  return SizedBox(
                    width: 74,
                    child: _CenterNavButton(
                      selected: selectedIndex == index,
                      item: items[index],
                      onTap: () => onSelected(index),
                    ),
                  );
                }
                return Expanded(
                  child: _NavButton(
                    selected: selectedIndex == index,
                    item: items[index],
                    onTap: () => onSelected(index),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.selected,
    required this.item,
    required this.onTap,
  });

  final bool selected;
  final AppNavItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  item.icon,
                  color: selected ? Colors.white : Colors.white54,
                  size: 21,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedOpacity(
                opacity: selected ? 1 : 0.58,
                duration: const Duration(milliseconds: 180),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterNavButton extends StatelessWidget {
  const _CenterNavButton({
    required this.selected,
    required this.item,
    required this.onTap,
  });

  final bool selected;
  final AppNavItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: selected ? 64 : 58,
              height: selected ? 64 : 58,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow,
              ),
              child: const Icon(Icons.center_focus_strong,
                  color: Colors.white, size: 29),
            ),
          ],
        ),
      ),
    );
  }
}
