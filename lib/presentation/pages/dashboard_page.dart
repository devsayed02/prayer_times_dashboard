import 'package:flutter/material.dart';
import 'package:prayer_times_dashboard/presentation/pages/analytics_page.dart';
import 'package:prayer_times_dashboard/presentation/pages/app_update_page.dart';
import 'package:prayer_times_dashboard/presentation/pages/events_management_page.dart';
import 'package:prayer_times_dashboard/presentation/pages/notification_history_page.dart';
import 'package:prayer_times_dashboard/presentation/pages/send_notification_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
    ),
    _NavItem(
      icon: Icons.analytics,
      label: 'Analytics',
    ),
    _NavItem(
      icon: Icons.notifications_active,
      label: 'Send Notification',
    ),
    _NavItem(
      icon: Icons.history,
      label: 'History',
    ),
    _NavItem(
      icon: Icons.event,
      label: 'Events',
    ),
    _NavItem(
      icon: Icons.system_update,
      label: 'App Update',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            extended: MediaQuery.of(context).size.width > 800,
            minExtendedWidth: 200,
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Icons.mosque,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                  if (MediaQuery.of(context).size.width > 800) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Prayer Times',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Dashboard',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: _navItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Main Content
          Expanded(
            child: _buildPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return _DashboardHome(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return const AnalyticsPage();
      case 2:
        return const SendNotificationPage();
      case 3:
        return const NotificationHistoryPage();
      case 4:
        return const EventsManagementPage();
      case 5:
        return const AppUpdatePage();
      default:
        return _DashboardHome(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class _DashboardHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _DashboardHome({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prayer Times Dashboard',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage notifications for Prayer Times app',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _DashboardCard(
                  icon: Icons.analytics,
                  title: 'User Analytics',
                  subtitle: 'View user statistics and trends',
                  color: Colors.teal,
                  onTap: () => onNavigate(1),
                ),
                _DashboardCard(
                  icon: Icons.notifications_active,
                  title: 'Send Notification',
                  subtitle: 'Send push notifications to all or single user',
                  color: Colors.blue,
                  onTap: () => onNavigate(2),
                ),
                _DashboardCard(
                  icon: Icons.history,
                  title: 'Notification History',
                  subtitle: 'View log of all sent notifications',
                  color: Colors.orange,
                  onTap: () => onNavigate(3),
                ),
                _DashboardCard(
                  icon: Icons.event,
                  title: 'Islamic Events',
                  subtitle: 'Manage holidays and Islamic events',
                  color: Colors.green,
                  onTap: () => onNavigate(4),
                ),
                _DashboardCard(
                  icon: Icons.system_update,
                  title: 'App Update',
                  subtitle: 'Control app version and force updates',
                  color: Colors.purple,
                  onTap: () => onNavigate(5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
