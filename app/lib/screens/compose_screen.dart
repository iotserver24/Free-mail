import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/compose_context.dart';

class ComposeScreen extends StatefulWidget {
  final ComposeContext? context;

  const ComposeScreen({super.key, this.context});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  String? _fromAddress;
  String? _threadId;
  bool _isLoading = false;
  bool _hasQuotedContext = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final client = Provider.of<ApiClient>(context, listen: false);
    _fromAddress ??= client.activeFromAddress ??
        (client.emails.isNotEmpty ? client.emails.first['email'] as String? : null);
  }

  @override
  void initState() {
    super.initState();
    _applyContext(widget.context);
  }

  @override
  void didUpdateWidget(covariant ComposeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context != widget.context) {
      _applyContext(widget.context);
    }
  }

  void _applyContext(ComposeContext? context) {
    if (context == null) return;
    _threadId = context.threadId;
    if (context.to != null && context.to!.isNotEmpty) {
      _toController.text = context.to!.join(', ');
    }
    if (context.cc != null && context.cc!.isNotEmpty) {
      _ccController.text = context.cc!.join(', ');
    }
    if (context.bcc != null && context.bcc!.isNotEmpty) {
      _bccController.text = context.bcc!.join(', ');
    }
    if (context.subject != null) {
      _subjectController.text = context.subject!;
    }
    if (context.body != null) {
      _bodyController.text = context.body!;
      _hasQuotedContext = context.body!.trim().isNotEmpty;
    } else {
      _hasQuotedContext = false;
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final client = Provider.of<ApiClient>(context, listen: false);
    final toList = _parseRecipients(_toController.text);
    final ccList = _parseRecipients(_ccController.text);
    final bccList = _parseRecipients(_bccController.text);

    if (toList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one recipient')),
      );
      return;
    }

    if (_fromAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sender address available')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await client.sendMessage(
      from: _fromAddress!,
      to: toList,
      cc: ccList,
      bcc: bccList,
      subject: _subjectController.text.trim(),
      body: _bodyController.text,
      threadId: _threadId,
    );
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  List<String> _parseRecipients(String raw) {
    return raw
        .split(RegExp(r'[,;\s]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  void _generateAI() {
    showDialog(
      context: context,
      builder: (context) {
        final promptController = TextEditingController();
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('AI Generate Email'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: promptController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Ask for a meeting on Friday',
                    ),
                    maxLines: 3,
                  ),
                  if (loading) const LinearProgressIndicator(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setDialogState(() => loading = true);
                          final client =
                              Provider.of<ApiClient>(context, listen: false);
                          final existingBody = _bodyController.text;
                          List<Map<String, dynamic>> conversation = [];
                          try {
                            conversation = await _buildConversationContext(client);
                          } catch (_) {
                            conversation = [];
                          }

                          final result = await client.generateEmail(
                            promptController.text,
                            context: conversation.isEmpty ? null : conversation,
                          );

                          if (!context.mounted) {
                            return;
                          }

                          if (result != null) {
                            setState(() {
                              final trimmed = result.trim();
                              if (_shouldPreserveQuotedTail() &&
                                  existingBody.trim().isNotEmpty) {
                                final tail = existingBody.trimLeft();
                                _bodyController.text =
                                    '$trimmed\n\n${tail.isEmpty ? existingBody : tail}';
                                _hasQuotedContext = true;
                              } else {
                                _bodyController.text = trimmed;
                              }
                            });
                            Navigator.pop(context);
                          } else {
                            setDialogState(() => loading = false);
                          }
                        },
                  child: const Text('Generate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _buildConversationContext(
      ApiClient client) async {
    final List<Map<String, dynamic>> context = [];
    if (_threadId != null) {
      try {
        final records = await client.fetchThread(_threadId!);
        for (final record in records) {
          final body = _extractBodyFromRecord(record);
          if (body.isEmpty) continue;
          context.add({
            'subject': record['subject'],
            'body': body,
            'direction': record['direction'],
            'sender': record['sender_email'],
            'createdAt': record['created_at'],
          });
        }
      } catch (_) {
        // Ignore thread fetch failures; we'll fall back to existing body.
      }
    }

    if (context.isEmpty && widget.context?.body?.isNotEmpty == true) {
      context.add({
        'subject': widget.context?.subject ?? _subjectController.text.trim(),
        'body': widget.context!.body!,
        'direction': 'inbound',
        'sender': widget.context?.to?.isNotEmpty == true
            ? widget.context!.to!.first
            : null,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    final draftBody = _bodyController.text.trim();
    if (draftBody.isNotEmpty) {
      context.add({
        'subject': _subjectController.text.trim(),
        'body': draftBody,
        'direction': 'draft',
        'sender': _fromAddress,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    return context;
  }

  String _extractBodyFromRecord(Map<String, dynamic> record) {
    final plain = record['body_plain'] as String?;
    if (plain != null && plain.trim().isNotEmpty) {
      return plain.trim();
    }
    final html = record['body_html'] as String?;
    if (html == null || html.isEmpty) return '';
    final stripped =
        html.replaceAll(RegExp(r'<[^>]+>'), ' ').replaceAll(RegExp(r'\s+'), ' ');
    return stripped.trim();
  }

  bool _shouldPreserveQuotedTail() {
    return _hasQuotedContext;
  }

  @override
  Widget build(BuildContext context) {
    final client = Provider.of<ApiClient>(context);
    final emailOptions =
        client.emails.where((email) => email['email'] != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _generateAI,
            tooltip: 'AI Generate',
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading ? null : _send,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _fromAddress,
              decoration: const InputDecoration(labelText: 'From'),
              items: emailOptions
                  .map(
                    (email) => DropdownMenuItem<String>(
                      value: email['email'] as String,
                      child: Text(email['email'] as String),
                    ),
                  )
                  .toList(),
              onChanged: emailOptions.isEmpty
                  ? null
                  : (value) => setState(() => _fromAddress = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _toController,
              decoration: const InputDecoration(
                labelText: 'To',
                hintText: 'email@example.com, ...',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ccController,
              decoration: const InputDecoration(
                labelText: 'Cc',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bccController,
              decoration: const InputDecoration(
                labelText: 'Bcc',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  hintText: 'Compose email',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
