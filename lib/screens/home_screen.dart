import 'package:flutter/material.dart';
import 'install_screen.dart';
import 'installed_apps_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  final ThemeService themeService;
  
  const HomeScreen({super.key, required this.themeService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    const SearchScreen(),
    const InstallScreen(),
    const InstalledAppsScreen(),
    SettingsScreen(themeService: widget.themeService),
  ];

  static const List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.search_rounded,
      selectedIcon: Icons.search_rounded,
      label: 'Discover',
      tooltip: 'Search and discover packages',
    ),
    NavigationItem(
      icon: Icons.file_download_outlined,
      selectedIcon: Icons.file_download_rounded,
      label: 'Install',
      tooltip: 'Install local package files',
    ),
    NavigationItem(
      icon: Icons.apps_outlined,
      selectedIcon: Icons.apps_rounded,
      label: 'Installed',
      tooltip: 'Manage installed packages',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
      tooltip: 'App settings and preferences',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('PackageArmor'),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: widget.themeService,
            builder: (context, child) {
              return PopupMenuButton<ThemeMode>(
                icon: Icon(widget.themeService.themeModeIcon),
                tooltip: 'Theme: ${widget.themeService.themeModeString}',
                onSelected: (ThemeMode mode) {
                  widget.themeService.setThemeMode(mode);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        Icon(
                          Icons.light_mode_rounded,
                          color: widget.themeService.themeMode == ThemeMode.light
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Light',
                          style: TextStyle(
                            fontWeight: widget.themeService.themeMode == ThemeMode.light
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        Icon(
                          Icons.dark_mode_rounded,
                          color: widget.themeService.themeMode == ThemeMode.dark
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Dark',
                          style: TextStyle(
                            fontWeight: widget.themeService.themeMode == ThemeMode.dark
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        Icon(
                          Icons.brightness_auto_rounded,
                          color: widget.themeService.themeMode == ThemeMode.system
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'System',
                          style: TextStyle(
                            fontWeight: widget.themeService.themeMode == ThemeMode.system
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              // Add refresh functionality
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWideScreen)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _navigationItems.length,
                      itemBuilder: (context, index) {
                        final item = _navigationItems[index];
                        final isSelected = _selectedIndex == index;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            selected: isSelected,
                            leading: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 24,
                            ),
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isWideScreen
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              destinations: _navigationItems.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                  tooltip: item.tooltip,
                );
              }).toList(),
            )
          : null,
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String tooltip;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.tooltip,
  });
}
