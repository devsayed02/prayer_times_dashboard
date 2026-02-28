import 'package:flutter/material.dart';
import 'package:prayer_times_dashboard/data/models/islamic_event.dart';
import 'package:prayer_times_dashboard/data/services/events_service.dart';

class EventsManagementPage extends StatefulWidget {
  const EventsManagementPage({super.key});

  @override
  State<EventsManagementPage> createState() => _EventsManagementPageState();
}

class _EventsManagementPageState extends State<EventsManagementPage> {
  final _service = EventsService();

  List<IslamicEvent> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _service.fetchEvents(_selectedYear);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _events = result.events;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _toggleEvent(IslamicEvent event) async {
    final result = await _service.toggleEvent(event.id);
    if (!mounted) return;

    _showSnackBar(result.message, result.success);
    if (result.success) _loadEvents();
  }

  Future<void> _deleteEvent(IslamicEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _service.deleteEvent(event.id);
    if (!mounted) return;

    _showSnackBar(result.message, result.success);
    if (result.success) _loadEvents();
  }

  void _showEventDialog({IslamicEvent? event}) {
    showDialog(
      context: context,
      builder: (context) => _EventFormDialog(
        event: event,
        selectedYear: _selectedYear,
        onSave: (savedEvent) async {
          final result = event == null
              ? await _service.createEvent(savedEvent)
              : await _service.updateEvent(savedEvent);

          if (!mounted) return;
          _showSnackBar(result.message, result.success);
          if (result.success) _loadEvents();
        },
      ),
    );
  }

  void _showSnackBar(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islamic Events'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          // Year selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<int>(
              value: _selectedYear,
              underline: const SizedBox(),
              items: List.generate(5, (i) {
                final year = DateTime.now().year - 1 + i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (year) {
                if (year != null) {
                  setState(() => _selectedYear = year);
                  _loadEvents();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
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
                onPressed: _loadEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 48,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No events for $_selectedYear',
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
        if (constraints.maxWidth > 700) {
          return _buildDataTable(theme);
        }
        return _buildListView(theme);
      },
    );
  }

  Widget _buildDataTable(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _events.map((event) {
            return DataRow(cells: [
              DataCell(Text(event.date)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _parseColor(event.colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Flexible(
                      child: Text(event.title,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              DataCell(Text(event.holidayType,
                  overflow: TextOverflow.ellipsis)),
              DataCell(_buildStatusChip(event)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit',
                    onPressed: () => _showEventDialog(event: event),
                  ),
                  IconButton(
                    icon: Icon(
                      event.isActive
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                    ),
                    tooltip: event.isActive ? 'Deactivate' : 'Activate',
                    onPressed: () => _toggleEvent(event),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20,
                        color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () => _deleteEvent(event),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        return Card(
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(event.colorHex).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  event.date.substring(8),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _parseColor(event.colorHex),
                  ),
                ),
              ),
            ),
            title: Text(event.title),
            subtitle: Text(event.holidayType),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusChip(event),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        _showEventDialog(event: event);
                      case 'toggle':
                        _toggleEvent(event);
                      case 'delete':
                        _deleteEvent(event);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(event.isActive
                          ? 'Deactivate'
                          : 'Activate'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(IslamicEvent event) {
    return Chip(
      label: Text(
        event.isActive ? 'Active' : 'Inactive',
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: event.isActive
          ? Colors.green.withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.15),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _parseColor(String hex) {
    try {
      final colorStr = hex.replaceFirst('#', '');
      return Color(int.parse(colorStr, radix: 16));
    } catch (_) {
      return Colors.green;
    }
  }
}

// ==================== Event Form Dialog ====================

class _EventFormDialog extends StatefulWidget {
  final IslamicEvent? event;
  final int selectedYear;
  final Future<void> Function(IslamicEvent event) onSave;

  const _EventFormDialog({
    this.event,
    required this.selectedYear,
    required this.onSave,
  });

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  late final TextEditingController _colorController;
  late String _holidayType;
  late int _year;
  bool _isSaving = false;

  static const _holidayTypes = [
    'Islamic Festival in Bangladesh',
    'National Holiday in Bangladesh',
    'Holiday in Bangladesh',
    'Cultural Festival in Bangladesh',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController =
        TextEditingController(text: e?.description ?? '');
    _dateController = TextEditingController(text: e?.date ?? '');
    _colorController =
        TextEditingController(text: e?.colorHex ?? '#FF4CAF50');
    _holidayType = e?.holidayType ?? _holidayTypes[0];
    if (!_holidayTypes.contains(_holidayType)) {
      _holidayType = _holidayTypes[0];
    }
    _year = e?.year ?? widget.selectedYear;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateController.text.isNotEmpty
          ? DateTime.tryParse(_dateController.text) ?? now
          : now,
      firstDate: DateTime(_year - 1),
      lastDate: DateTime(_year + 2),
    );
    if (picked != null) {
      _dateController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _year = picked.year);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final event = IslamicEvent(
      id: widget.event?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      holidayType: _holidayType,
      date: _dateController.text.trim(),
      colorHex: _colorController.text.trim(),
      year: _year,
      isActive: widget.event?.isActive ?? true,
    );

    await widget.onSave(event);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Event' : 'Add Event'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _holidayType,
                  decoration: const InputDecoration(
                    labelText: 'Holiday Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _holidayTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _holidayType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date (YYYY-MM-DD) *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ),
                  readOnly: true,
                  onTap: _pickDate,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _colorController,
                  decoration: InputDecoration(
                    labelText: 'Color Hex',
                    border: const OutlineInputBorder(),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _tryParseColor(_colorController.text),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Color _tryParseColor(String hex) {
    try {
      final colorStr = hex.replaceFirst('#', '');
      return Color(int.parse(colorStr, radix: 16));
    } catch (_) {
      return Colors.green;
    }
  }
}
