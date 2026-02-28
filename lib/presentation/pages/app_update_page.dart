import 'package:flutter/material.dart';
import 'package:prayer_times_dashboard/data/models/app_update.dart';
import 'package:prayer_times_dashboard/data/services/app_update_service.dart';

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({super.key});

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  final _service = AppUpdateService();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _changeLogsController = TextEditingController();
  final _latestVersionController = TextEditingController();
  final _minVersionController = TextEditingController();
  final _storeUrlController = TextEditingController();
  final _iosStoreUrlController = TextEditingController();

  bool _forceUpdate = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _changeLogsController.dispose();
    _latestVersionController.dispose();
    _minVersionController.dispose();
    _storeUrlController.dispose();
    _iosStoreUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _service.fetchAppUpdate();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success && result.data != null) {
        final d = result.data!;
        _titleController.text = d.title;
        _changeLogsController.text = d.changeLogs;
        _latestVersionController.text = d.latestVersion;
        _minVersionController.text = d.minSupportedVersion;
        _storeUrlController.text = d.storeUrl;
        _iosStoreUrlController.text = d.iosStoreUrl;
        _forceUpdate = d.forceUpdate;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final appUpdate = AppUpdate(
      title: _titleController.text.trim(),
      changeLogs: _changeLogsController.text.trim(),
      latestVersion: _latestVersionController.text.trim(),
      minSupportedVersion: _minVersionController.text.trim(),
      forceUpdate: _forceUpdate,
      storeUrl: _storeUrlController.text.trim(),
      iosStoreUrl: _iosStoreUrlController.text.trim(),
    );

    final result = await _service.saveAppUpdate(appUpdate);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Update Control'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Reload',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Version Info
                _SectionTitle(title: 'Version Information'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latestVersionController,
                        decoration: const InputDecoration(
                          labelText: 'Latest Version *',
                          hintText: '1.5.0',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.new_releases),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minVersionController,
                        decoration: const InputDecoration(
                          labelText: 'Min Supported Version',
                          hintText: '1.0.0',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Force Update Toggle
                _SectionTitle(title: 'Update Policy'),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Force Update'),
                  subtitle: Text(
                    _forceUpdate
                        ? 'Users MUST update to continue using the app'
                        : 'Users can skip this update',
                    style: TextStyle(
                      color: _forceUpdate ? Colors.red : null,
                    ),
                  ),
                  value: _forceUpdate,
                  onChanged: (v) => setState(() => _forceUpdate = v),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  activeTrackColor: Colors.red.shade100,
                ),

                const SizedBox(height: 24),

                // Dialog Content
                _SectionTitle(title: 'Update Dialog'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Dialog Title',
                    hintText: 'Update Available',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _changeLogsController,
                  decoration: const InputDecoration(
                    labelText: 'Changelog (HTML supported)',
                    hintText: '<ul><li>Bug fixes</li><li>New features</li></ul>',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  minLines: 3,
                ),

                const SizedBox(height: 24),

                // Store URLs
                _SectionTitle(title: 'Store URLs'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _storeUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Android Play Store URL',
                    hintText: 'https://play.google.com/store/apps/details?id=...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.android),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _iosStoreUrlController,
                  decoration: const InputDecoration(
                    labelText: 'iOS App Store URL',
                    hintText: 'https://apps.apple.com/app/...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.apple),
                  ),
                ),

                const SizedBox(height: 24),

                // Current Status Preview
                _SectionTitle(title: 'Current Status'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _StatusRow(
                          label: 'Latest Version',
                          value: _latestVersionController.text.isEmpty
                              ? 'Not set'
                              : _latestVersionController.text,
                        ),
                        _StatusRow(
                          label: 'Min Version',
                          value: _minVersionController.text.isEmpty
                              ? 'Not set'
                              : _minVersionController.text,
                        ),
                        _StatusRow(
                          label: 'Force Update',
                          value: _forceUpdate ? 'ON' : 'OFF',
                          valueColor: _forceUpdate ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Settings',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: valueColor != null ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
