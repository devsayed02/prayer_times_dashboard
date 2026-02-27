import 'package:flutter/material.dart';
import 'package:prayer_times_dashboard/data/services/fcm_notification_sender.dart';

class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key});

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tokenController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _actionUrlController = TextEditingController();

  final _sender = FcmNotificationSender();

  SendTarget _selectedTarget = SendTarget.allUsers;
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tokenController.dispose();
    _imageUrlController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final result = await _sender.sendNotification(
      target: _selectedTarget,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      fcmToken: _selectedTarget == SendTarget.singleUser
          ? _tokenController.text.trim()
          : null,
      imageUrl: _imageUrlController.text.trim(),
      actionUrl: _actionUrlController.text.trim(),
    );

    setState(() => _isSending = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    if (result.success) {
      _titleController.clear();
      _bodyController.clear();
      _imageUrlController.clear();
      _actionUrlController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notification'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Target Selection
              _SectionTitle(title: 'Target'),
              const SizedBox(height: 8),
              SegmentedButton<SendTarget>(
                segments: const [
                  ButtonSegment(
                    value: SendTarget.allUsers,
                    label: Text('All Users'),
                    icon: Icon(Icons.groups),
                  ),
                  ButtonSegment(
                    value: SendTarget.singleUser,
                    label: Text('Single User'),
                    icon: Icon(Icons.person),
                  ),
                ],
                selected: {_selectedTarget},
                onSelectionChanged: (selected) {
                  setState(() => _selectedTarget = selected.first);
                },
              ),

              // FCM Token (for single user)
              if (_selectedTarget == SendTarget.singleUser) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'FCM Device Token *',
                    hintText: 'Enter user FCM token',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  validator: (value) {
                    if (_selectedTarget == SendTarget.singleUser &&
                        (value == null || value.trim().isEmpty)) {
                      return 'FCM token is required for single user';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Notification Content
              _SectionTitle(title: 'Notification Content'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Notification title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body *',
                  hintText: 'Notification message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Body is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Optional Fields
              _SectionTitle(title: 'Optional Data'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.png',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _actionUrlController,
                decoration: const InputDecoration(
                  labelText: 'Action URL',
                  hintText: 'Deep link or URL',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),

              const SizedBox(height: 24),

              // JSON Preview
              _SectionTitle(title: 'Preview'),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: Listenable.merge([
                  _titleController,
                  _bodyController,
                  _tokenController,
                  _imageUrlController,
                  _actionUrlController,
                ]),
                builder: (context, _) => _JsonPreviewCard(
                  target: _selectedTarget,
                  title: _titleController.text,
                  body: _bodyController.text,
                  token: _tokenController.text,
                  imageUrl: _imageUrlController.text,
                  actionUrl: _actionUrlController.text,
                ),
              ),

              const SizedBox(height: 24),

              // Send Button
              FilledButton.icon(
                onPressed: _isSending ? null : _sendNotification,
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _isSending ? 'Sending...' : 'Send Notification',
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
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _JsonPreviewCard extends StatelessWidget {
  final SendTarget target;
  final String title;
  final String body;
  final String token;
  final String imageUrl;
  final String actionUrl;

  const _JsonPreviewCard({
    required this.target,
    required this.title,
    required this.body,
    required this.token,
    required this.imageUrl,
    required this.actionUrl,
  });

  @override
  Widget build(BuildContext context) {
    final targetLine = target == SendTarget.allUsers
        ? '"topic": "all_users"'
        : '"token": "${token.isEmpty ? '<FCM_TOKEN>' : _truncate(token)}"';

    final preview =
        '''
{
  "message": {
    $targetLine,
    "notification": {
      "title": "${title.isEmpty ? '<title>' : title}",
      "body": "${body.isEmpty ? '<body>' : body}"
    },
    "data": {
      "type": "push",
      "imageUrl": "$imageUrl",
      "actionUrl": "$actionUrl"
    }
  }
}''';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        preview,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  String _truncate(String text) {
    if (text.length <= 30) return text;
    return '${text.substring(0, 15)}...${text.substring(text.length - 10)}';
  }
}
