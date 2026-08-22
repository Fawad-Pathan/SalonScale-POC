import 'package:flutter/material.dart';

import '../core/design/app_colors.dart';
import '../core/design/app_radius.dart';
import '../core/design/app_spacing.dart';
import '../features/assistant/presentation/inventory_assistant_screen.dart';
import '../features/catalogue/presentation/catalogue_screen.dart';
import '../features/history/presentation/scan_history_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/scanning/presentation/scan_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 2});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late var _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const InventoryScreen(),
      ScanScreen(
        isActive: _index == 2,
        onMenu: () => _showSimpleMenu(context),
      ),
      const ScanHistoryScreen(),
      const InventoryAssistantScreen(),
      const CatalogueScreen(),
    ];

    return Scaffold(
      body: pages[_index],
    );
  }

  Future<void> _showSimpleMenu(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                _MenuItem(
                  icon: Icons.center_focus_strong,
                  label: 'Scanner',
                  onTap: () => Navigator.of(context).pop(2),
                ),
                _MenuItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  onTap: () => Navigator.of(context).pop(0),
                ),
                _MenuItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  onTap: () => Navigator.of(context).pop(1),
                ),
                _MenuItem(
                  icon: Icons.view_in_ar_rounded,
                  label: 'Product Catalogue',
                  onTap: () => Navigator.of(context).pop(5),
                ),
                _MenuItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  onTap: () => Navigator.of(context).pop(3),
                ),
                _MenuItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Assistant',
                  onTap: () => Navigator.of(context).pop(4),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _index = selected);
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          leading: Icon(icon, color: AppColors.indigo),
          title: Text(
            label,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}
