import 'package:flutter/material.dart';
import 'package:prayer_times_dashboard/data/models/user_analytics.dart';
import 'package:prayer_times_dashboard/data/services/analytics_service.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _service = AnalyticsService();

  UserAnalytics? _analytics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _service.fetchAnalytics();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success && result.data != null) {
        _analytics = result.data;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Analytics'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48,
                  color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _analytics!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(theme, data),
          const SizedBox(height: 24),
          _buildNotificationStats(theme, data.notificationStats),
          const SizedBox(height: 24),
          _buildDistributionSection(
            theme,
            title: 'Platform Distribution',
            icon: Icons.devices,
            items: data.platformDistribution,
          ),
          const SizedBox(height: 24),
          _buildDistributionSection(
            theme,
            title: 'App Version Adoption',
            icon: Icons.system_update,
            items: data.appVersionDistribution.take(8).toList(),
            extraCount: data.appVersionDistribution.length > 8
                ? data.appVersionDistribution.length - 8
                : 0,
          ),
          const SizedBox(height: 24),
          _buildDistributionSection(
            theme,
            title: 'Top Device Brands',
            icon: Icons.phone_android,
            items: data.brandDistribution,
          ),
          const SizedBox(height: 24),
          _buildRegistrationTrend(theme, data.registrationTrend),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, UserAnalytics data) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          icon: Icons.people,
          label: 'Total Users',
          value: _formatNumber(data.totalUsers),
          color: Colors.blue,
        ),
        _SummaryCard(
          icon: Icons.access_time,
          label: 'Active (24h)',
          value: _formatNumber(data.activeUsers.last24h),
          color: Colors.green,
        ),
        _SummaryCard(
          icon: Icons.date_range,
          label: 'Active (7d)',
          value: _formatNumber(data.activeUsers.last7d),
          color: Colors.orange,
        ),
        _SummaryCard(
          icon: Icons.calendar_month,
          label: 'Active (30d)',
          value: _formatNumber(data.activeUsers.last30d),
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildNotificationStats(ThemeData theme, NotificationStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Notification Delivery',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Based on send attempts from dashboard',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 32,
              runSpacing: 12,
              children: [
                _StatItem(
                  label: 'Total',
                  value: stats.total.toString(),
                  color: theme.colorScheme.primary,
                ),
                _StatItem(
                  label: 'Success',
                  value: stats.success.toString(),
                  color: Colors.green,
                ),
                _StatItem(
                  label: 'Failed',
                  value: stats.fail.toString(),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (stats.total > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    if (stats.success > 0)
                      Expanded(
                        flex: stats.success,
                        child: Container(
                          height: 28,
                          color: Colors.green,
                          alignment: Alignment.center,
                          child: stats.successRate >= 15
                              ? Text(
                                  '${stats.successRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    if (stats.fail > 0)
                      Expanded(
                        flex: stats.fail,
                        child: Container(
                          height: 28,
                          color: Colors.red,
                          alignment: Alignment.center,
                          child: stats.failRate >= 15
                              ? Text(
                                  '${stats.failRate.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _LegendDot(color: Colors.green, label: 'Success'),
                  const SizedBox(width: 16),
                  _LegendDot(color: Colors.red, label: 'Failed'),
                ],
              ),
            ] else
              Text(
                'No notifications sent yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<DistributionItem> items,
    int extraCount = 0,
  }) {
    final maxCount = items.isNotEmpty
        ? items.map((e) => e.count).reduce((a, b) => a > b ? a : b)
        : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(
                'No data available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            item.label,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final ratio = maxCount > 0
                                  ? item.count / maxCount
                                  : 0.0;
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: constraints.maxWidth * ratio,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    '${item.count}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )),
            if (extraCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'and $extraCount more versions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationTrend(ThemeData theme, List<TrendItem> trend) {
    final maxCount = trend.isNotEmpty
        ? trend.map((e) => e.count).reduce((a, b) => a > b ? a : b)
        : 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'New User Registrations (Last 30 Days)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (trend.isEmpty)
              Text(
                'No data available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: trend.map((item) {
                    final ratio =
                        maxCount > 0 ? item.count / maxCount : 0.0;
                    return Expanded(
                      child: Tooltip(
                        message: '${item.date}: ${item.count} new users',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            height: (ratio * 140).clamp(2.0, 140.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (trend.isNotEmpty)
                    Text(
                      trend.first.date.substring(5),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (trend.length > 1)
                    Text(
                      trend[trend.length ~/ 2].date.substring(5),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (trend.length > 1)
                    Text(
                      trend.last.date.substring(5),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
