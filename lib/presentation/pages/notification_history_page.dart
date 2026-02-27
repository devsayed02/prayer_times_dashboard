import 'package:flutter/material.dart';
import 'package:prayer_times_dashboard/data/models/notification_log.dart';
import 'package:prayer_times_dashboard/data/services/notification_history_service.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  final _service = NotificationHistoryService();

  List<NotificationLog> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastDocId;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _service.fetchHistory();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _logs = result.logs;
        _lastDocId = result.lastDocId;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _loadMore() async {
    if (_lastDocId == null || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final result = await _service.fetchHistory(startAfterDocId: _lastDocId);

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      if (result.success) {
        _logs.addAll(result.logs);
        _lastDocId =
            result.logs.isEmpty ? null : result.lastDocId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadHistory,
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
                onPressed: _loadHistory,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, size: 48,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No notifications sent yet.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildDataTable(theme);
        }
        return _buildListView(theme);
      },
    );
  }

  Widget _buildDataTable(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTable(
            columns: const [
              DataColumn(label: Text('Timestamp')),
              DataColumn(label: Text('Target')),
              DataColumn(label: Text('Title')),
              DataColumn(label: Text('Body')),
              DataColumn(label: Text('Status')),
            ],
            rows: _logs.map((log) {
              return DataRow(cells: [
                DataCell(Text(_formatTimestamp(log.timestamp))),
                DataCell(_buildTargetChip(log)),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(log.title, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(log.body, overflow: TextOverflow.ellipsis),
                  ),
                ),
                DataCell(_buildStatusChip(log)),
              ]);
            }).toList(),
          ),
          if (_lastDocId != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _isLoadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: _loadMore,
                        child: const Text('Load More'),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _logs.length + (_lastDocId != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _logs.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: _loadMore,
                      child: const Text('Load More'),
                    ),
            ),
          );
        }

        final log = _logs[index];
        return Card(
          child: ListTile(
            leading: Icon(
              log.isSuccess ? Icons.check_circle : Icons.error,
              color: log.isSuccess ? Colors.green : Colors.red,
            ),
            title: Text(log.title),
            subtitle: Text(
              '${_formatTimestamp(log.timestamp)} • ${log.isAllUsers ? "All Users" : "Single User"}',
            ),
            trailing: _buildStatusChip(log),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'N/A';
    final local = timestamp.toLocal();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final amPm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$min $amPm';
  }

  Widget _buildTargetChip(NotificationLog log) {
    return Chip(
      label: Text(
        log.isAllUsers ? 'All Users' : 'Single',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: log.isAllUsers
          ? Colors.blue.withValues(alpha: 0.15)
          : Colors.orange.withValues(alpha: 0.15),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatusChip(NotificationLog log) {
    return Chip(
      avatar: Icon(
        log.isSuccess ? Icons.check : Icons.close,
        size: 16,
        color: log.isSuccess ? Colors.green : Colors.red,
      ),
      label: Text(
        log.isSuccess ? 'Sent' : 'Failed',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: log.isSuccess
          ? Colors.green.withValues(alpha: 0.15)
          : Colors.red.withValues(alpha: 0.15),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
