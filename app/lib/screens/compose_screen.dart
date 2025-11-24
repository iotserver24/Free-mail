import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/compose_context.dart';
import '../services/catbox_uploader.dart';

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
  final List<ComposeAttachment> _attachments = [];
  final CatboxUploader _catboxUploader = CatboxUploader();
  bool _isLoading = false;
  bool _hasQuotedContext = false;
  bool _uploadingAttachments = false;
  String? _uploadError;

  static const int _maxFileSizeBytes = 20 * 1024 * 1024;
  String? _currentUploadName;
  double? _currentUploadProgress;

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

    if (_uploadingAttachments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for uploads to finish')),
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
      attachments: _attachments
          .map((att) => {
                'filename': att.filename,
                'url': att.url,
                if (att.mimeType != null) 'contentType': att.mimeType,
                if (att.sizeBytes != null) 'size': att.sizeBytes,
              })
          .toList(),
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

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result == null) return;

    setState(() {
      _uploadingAttachments = true;
      _uploadError = null;
    });

    for (final file in result.files) {
      final path = file.path;
      if (path == null) {
        setState(() {
          _uploadError = 'Cannot read ${file.name} on this platform.';
        });
        continue;
      }
      if (file.size > _maxFileSizeBytes) {
        setState(() {
          _uploadError =
              'File ${file.name} exceeds ${(_maxFileSizeBytes / (1024 * 1024)).toStringAsFixed(0)}MB limit.';
        });
        continue;
      }
      try {
        setState(() {
          _currentUploadName = file.name;
          _currentUploadProgress = 0;
        });
        final url =
            await _catboxUploader.uploadFile(
          path,
          filename: file.name,
          onProgress: (sent, total) {
            if (!mounted) return;
            setState(() {
              _currentUploadProgress =
                  total == 0 ? null : sent / total.toDouble();
            });
          },
        );
        if (!mounted) return;
        setState(() {
          _attachments.add(
            ComposeAttachment(
              filename: file.name,
              url: url,
              sizeBytes: file.size,
              mimeType: _guessMimeType(file),
            ),
          );
          _currentUploadProgress = 1;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _uploadError = 'Failed to upload ${file.name}';
        });
      }
    }

    if (mounted) {
      setState(() {
        _uploadingAttachments = false;
        _currentUploadName = null;
        _currentUploadProgress = null;
      });
    }
  }

  void _removeAttachment(ComposeAttachment attachment) {
    setState(() {
      _attachments.remove(attachment);
    });
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
                              final trimmed = result.body.trim();
                              if (_shouldPreserveQuotedTail() &&
                                  existingBody.trim().isNotEmpty) {
                                final tail = existingBody.trimLeft();
                                _bodyController.text =
                                    '$trimmed\n\n${tail.isEmpty ? existingBody : tail}';
                                _hasQuotedContext = true;
                              } else {
                                _bodyController.text = trimmed;
                              }
                              if ((_subjectController.text.trim().isEmpty) &&
                                  result.subject != null &&
                                  result.subject!.trim().isNotEmpty) {
                                _subjectController.text =
                                    result.subject!.trim();
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
        child: ListView(
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
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                hintText: 'Compose email',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 10,
            ),
            const SizedBox(height: 16),
            _AttachmentEditor(
              attachments: _attachments,
              uploading: _uploadingAttachments,
              uploadError: _uploadError,
              currentUploadName: _currentUploadName,
              uploadProgress: _currentUploadProgress,
              onAdd: _pickAttachments,
              onRemove: _removeAttachment,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentEditor extends StatelessWidget {
  const _AttachmentEditor({
    required this.attachments,
    required this.uploading,
    required this.uploadError,
    required this.currentUploadName,
    required this.uploadProgress,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ComposeAttachment> attachments;
  final bool uploading;
  final String? uploadError;
  final String? currentUploadName;
  final double? uploadProgress;
  final VoidCallback onAdd;
  final void Function(ComposeAttachment attachment) onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: uploading ? null : onAdd,
              icon: const Icon(Icons.attach_file),
              label: Text(
                uploading
                    ? 'Uploading ${currentUploadName ?? ''}...'
                    : 'Add attachment',
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Each file must be under 20MB. Files upload via Catbox.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        if (uploading)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUploadName ?? 'Uploading…',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: uploadProgress),
              ],
            ),
          ),
        if (uploadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              uploadError!,
              style: TextStyle(color: colors.error),
            ),
          ),
        if (attachments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: attachments
                .map(
                  (attachment) => _AttachmentCard(
                    attachment: attachment,
                    onRemove: () => onRemove(attachment),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.attachment,
    required this.onRemove,
  });

  final ComposeAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ),
          Icon(
            Icons.insert_drive_file_outlined,
            color: colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            attachment.filename,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          if (attachment.sizeBytes != null)
            Text(
              _formatSize(attachment.sizeBytes!),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class ComposeAttachment {
  final String filename;
  final String url;
  final int? sizeBytes;
  final String? mimeType;

  ComposeAttachment({
    required this.filename,
    required this.url,
    this.sizeBytes,
    this.mimeType,
  });
}

String? _guessMimeType(PlatformFile file) {
  final ext = file.extension?.toLowerCase();
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'gif':
      return 'image/gif';
    case 'webp':
      return 'image/webp';
    case 'pdf':
      return 'application/pdf';
    case 'txt':
      return 'text/plain';
    case 'md':
      return 'text/markdown';
    case 'json':
      return 'application/json';
    default:
      return null;
  }
}
