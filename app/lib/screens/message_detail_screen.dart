import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../api/api_client.dart';
import '../models/compose_context.dart';
import 'compose_screen.dart';

class MessageDetailScreen extends StatefulWidget {
  final Map<String, dynamic> message;

  const MessageDetailScreen({super.key, required this.message});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final DateFormat _dateFormat = DateFormat.yMMMd().add_jm();
  bool _loadingThread = false;
  String? _error;
  List<Map<String, dynamic>> _threadMessages = [];

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  Future<void> _loadThread() async {
    final client = Provider.of<ApiClient>(context, listen: false);
    setState(() {
      _loadingThread = true;
      _error = null;
    });

    // Mark as read if unread
    if (widget.message['is_read'] != true) {
      client.updateMessageStatus(widget.message['id'] as String, true);
    }

    try {
      if (widget.message['thread_id'] != null) {
        final records =
            await client.fetchThread(widget.message['thread_id'] as String);
        if (!mounted) return;
        setState(() {
          _threadMessages = records.isNotEmpty ? records : [widget.message];
        });
      } else {
        final detail =
            await client.fetchMessageDetail(widget.message['id'] as String);
        if (!mounted) return;
        setState(() {
          _threadMessages = [detail];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load conversation';
        _threadMessages = [widget.message];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingThread = false;
        });
      }
    }
  }

  void _summarize(BuildContext context) {
    final client = Provider.of<ApiClient>(context, listen: false);
    final body =
        widget.message['body_plain'] ?? widget.message['body_html'] ?? '';

    if (body == null || body.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<String?>(
          future: client.summarizeEmail(body),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(content: LinearProgressIndicator());
            }
            return AlertDialog(
              title: const Text('Summary'),
              content: SingleChildScrollView(
                child: Text(snapshot.data ?? 'Failed to summarize'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _handleReply() {
    final target = widget.message;
    final contextPayload = _buildReplyContext(target);
    _openComposer(contextPayload);
  }

  void _handleForward() {
    final target = widget.message;
    final contextPayload = _buildForwardContext(target);
    _openComposer(contextPayload);
  }

  void _openComposer(ComposeContext contextPayload) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComposeScreen(context: contextPayload),
      ),
    );
  }

  ComposeContext _buildReplyContext(Map<String, dynamic> entry) {
    final direction = entry['direction'] as String? ?? 'inbound';
    List<String> to;
    if (direction == 'outbound') {
      final recipients = entry['recipient_emails'] as List<dynamic>? ?? [];
      to = recipients.cast<String>();
    } else {
      final sender = entry['sender_email'] as String?;
      to = sender != null ? [sender] : <String>[];
    }
    final subject = _ensurePrefix(entry['subject'] as String?, 'Re');
    final timestamp = entry['created_at'] as String?;
    final sender = entry['sender_email'] as String? ?? 'Unknown';
    final quoted = _quoteBody(_plainBody(entry) ?? '',
        sender: sender, timestamp: timestamp);

    return ComposeContext(
      to: to,
      subject: subject,
      body: '\n\n$quoted\n\n',
      threadId: entry['thread_id'] as String?,
    );
  }

  ComposeContext _buildForwardContext(Map<String, dynamic> entry) {
    final subject = _ensurePrefix(entry['subject'] as String?, 'Fwd');
    final timestamp = entry['created_at'] as String?;
    final sender = entry['sender_email'] as String? ?? 'Unknown';
    final recipients =
        (entry['recipient_emails'] as List<dynamic>? ?? []).join(', ');

    final headerLines = [
      '---------- Forwarded message ----------',
      'From: $sender',
      if (timestamp != null)
        'Date: ${_formatTimestamp(DateTime.tryParse(timestamp))}',
      'Subject: ${entry['subject'] ?? '(no subject)'}',
      'To: ${recipients.isNotEmpty ? recipients : "Undisclosed recipients"}',
      '',
    ];
    final body = '\n\n${headerLines.join("\n")}${_plainBody(entry) ?? ''}\n\n';

    return ComposeContext(
      subject: subject,
      body: body,
      threadId: entry['thread_id'] as String?,
    );
  }

  String _ensurePrefix(String? subject, String prefix) {
    if (subject == null || subject.isEmpty) {
      return '$prefix:';
    }
    final regex = RegExp('^$prefix:', caseSensitive: false);
    return regex.hasMatch(subject) ? subject : '$prefix: $subject';
  }

  String? _plainBody(Map<String, dynamic> entry) {
    final bodyPlain = entry['body_plain'] as String?;
    if (bodyPlain != null && bodyPlain.trim().isNotEmpty) {
      return bodyPlain;
    }
    final bodyHtml = entry['body_html'] as String?;
    if (bodyHtml != null && bodyHtml.isNotEmpty) {
      final stripped = bodyHtml.replaceAll(RegExp(r'<[^>]+>'), ' ');
      return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return null;
  }

  String _quoteBody(String body, {required String sender, String? timestamp}) {
    final formattedDate =
        timestamp != null ? _formatTimestamp(DateTime.tryParse(timestamp)) : '';
    final header = 'On $formattedDate, $sender wrote:\n';
    final quoted = body
        .split(RegExp(r'\r?\n'))
        .map((line) => '> ${line.trimRight()}')
        .join('\n');
    return '$header$quoted';
  }

  String _formatTimestamp(DateTime? date) {
    if (date == null) return '';
    // Convert UTC to IST (UTC+5:30)
    final istDate = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return _dateFormat.format(istDate);
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.message['subject'] as String? ?? '(No Subject)';
    final sender = widget.message['sender_email'] as String? ?? 'Unknown';
    final createdAt = widget.message['created_at'] as String?;
    final createdDate = createdAt != null ? DateTime.tryParse(createdAt) : null;
    final createdAtLabel =
        createdDate != null ? _formatTimestamp(createdDate) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadingThread ? null : _loadThread,
            tooltip: 'Reload thread',
          ),
          IconButton(
            icon: const ImageIcon(
              AssetImage('assets/summary-logo.webp'),
              size: 24,
            ),
            onPressed: () => _summarize(context),
            tooltip: 'Summarize',
          ),
          if (widget.message['folder'] == 'trash')
            IconButton(
              icon: const Icon(Icons.restore_from_trash),
              onPressed: () {
                final client = Provider.of<ApiClient>(context, listen: false);
                client.moveMessageToFolder(
                    widget.message['id'] as String, 'inbox');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restored to Inbox')),
                );
              },
              tooltip: 'Restore',
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                final client = Provider.of<ApiClient>(context, listen: false);
                client.moveMessageToFolder(
                    widget.message['id'] as String, 'trash');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Moved to Bin')),
                );
              },
              tooltip: 'Delete',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_unread') {
                final client = Provider.of<ApiClient>(context, listen: false);
                client.updateMessageStatus(
                    widget.message['id'] as String, false);
                Navigator.pop(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'mark_unread',
                  child: Text('Mark as unread'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _MessageHeader(
            subject: subject,
            sender: sender,
            recipient: widget.message['recipient_emails'] is List
                ? (widget.message['recipient_emails'] as List)
                    .cast<String>()
                    .join(', ')
                : widget.message['recipient_emails']?.toString() ?? '—',
            createdAt: createdAtLabel,
          ),
          Expanded(
            child: _loadingThread
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ThreadError(message: _error!, onRetry: _loadThread)
                    : RefreshIndicator(
                        onRefresh: _loadThread,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          itemBuilder: (context, index) {
                            final entry = _threadMessages[index];
                            final entryDate = entry['created_at'] != null
                                ? DateTime.tryParse(
                                    entry['created_at'] as String)
                                : null;
                            final direction =
                                entry['direction'] as String? ?? 'inbound';
                            final isOutbound = direction == 'outbound';
                            final recipients =
                                (entry['recipient_emails'] as List<dynamic>?)
                                        ?.cast<String>() ??
                                    <String>[];
                            final attachments =
                                (entry['attachments'] as List<dynamic>?)
                                        ?.whereType<Map>()
                                        .map(
                                          (att) =>
                                              Map<String, dynamic>.from(att),
                                        )
                                        .toList() ??
                                    const <Map<String, dynamic>>[];
                            return _MessageBubble(
                              isOutbound: isOutbound,
                              sender: isOutbound
                                  ? 'You'
                                  : (entry['sender_email'] as String? ??
                                      'Unknown'),
                              recipients: recipients,
                              timestamp: entryDate != null
                                  ? _formatTimestamp(entryDate)
                                  : null,
                              body: _plainBody(entry) ?? '',
                              hasHtml:
                                  (entry['body_html'] as String?)?.isNotEmpty ==
                                      true,
                              attachments: attachments,
                              statusLabel: isOutbound && index == 0
                                  ? 'Latest reply'
                                  : isOutbound
                                      ? 'Replied'
                                      : null,
                            )
                                .animate()
                                .fade(duration: 400.ms, delay: (100 * index).ms)
                                .slideY(begin: 0.1, end: 0);
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount: _threadMessages.length,
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleReply,
                icon: const Icon(Icons.reply_outlined),
                label: const Text('Reply'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _handleForward,
                icon: const Icon(Icons.forward_outlined),
                label: const Text('Forward'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageHeader extends StatelessWidget {
  final String subject;
  final String sender;
  final String recipient;
  final String? createdAt;

  const _MessageHeader({
    required this.subject,
    required this.sender,
    required this.recipient,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                child: Text(sender.isNotEmpty
                    ? sender.substring(0, 1).toUpperCase()
                    : '?'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'To: $recipient',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (createdAt != null)
                Text(
                  createdAt!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isOutbound;
  final String sender;
  final List<String> recipients;
  final String? timestamp;
  final String body;
  final bool hasHtml;
  final String? statusLabel;
  final List<Map<String, dynamic>> attachments;

  const _MessageBubble({
    required this.isOutbound,
    required this.sender,
    required this.recipients,
    required this.timestamp,
    required this.body,
    required this.hasHtml,
    this.statusLabel,
    this.attachments = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final baseColor = isOutbound
        ? colors.primaryContainer.withValues(alpha: 0.18)
        : colors.surfaceContainerHighest.withValues(alpha: 0.45);
    final borderColor = isOutbound
        ? colors.primaryContainer
        : colors.outlineVariant.withValues(alpha: 0.4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                      isOutbound ? colors.primary : colors.secondaryContainer,
                  foregroundColor: isOutbound
                      ? colors.onPrimary
                      : colors.onSecondaryContainer,
                  child: Text(sender.isNotEmpty
                      ? sender.substring(0, 1).toUpperCase()
                      : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sender,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (recipients.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'To: ${recipients.join(", ")}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (timestamp != null)
                  Text(
                    timestamp!,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            if (statusLabel != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOutbound
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOutbound ? colors.primary : colors.secondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildBodyNodes(colors),
            ),
            if (hasHtml)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Rich formatting was detected in this message.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            if (attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: attachments
                          .map(
                            (att) => _AttachmentPreview(
                              filename: att['filename']?.toString() ?? 'file',
                              url: att['url']?.toString() ?? '',
                              sizeBytes: att['size_bytes'] is int
                                  ? att['size_bytes'] as int
                                  : null,
                              type: att['mimetype']?.toString(),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBodyNodes(ColorScheme colors) {
    final lines = body.split(RegExp(r'\r?\n'));
    final widgets = <Widget>[];
    final quoteBuffer = <String>[];

    void flushQuoteBuffer() {
      if (quoteBuffer.isEmpty) return;
      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: colors.primary,
                width: 3,
              ),
            ),
          ),
          child: SelectableText(
            quoteBuffer.join('\n'),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
      quoteBuffer.clear();
    }

    for (final rawLine in lines) {
      final trimmedLeft = rawLine.trimLeft();
      if (trimmedLeft.startsWith('>')) {
        final cleaned =
            trimmedLeft.replaceFirst(RegExp(r'^>+\s*'), '').trimRight();
        quoteBuffer.add(cleaned.isEmpty ? ' ' : cleaned);
        continue;
      }

      flushQuoteBuffer();

      if (rawLine.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(
          SelectableText(
            rawLine,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        );
      }
    }

    flushQuoteBuffer();

    if (widgets.isEmpty) {
      widgets.add(
        SelectableText(
          body,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
      );
    }

    return widgets;
  }
}

class _AttachmentPreview extends StatelessWidget {
  final String filename;
  final String url;
  final int? sizeBytes;
  final String? type;

  const _AttachmentPreview({
    required this.filename,
    required this.url,
    this.sizeBytes,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isImage = _isImage(type, filename);
    const previewSize = 100.0;

    return InkWell(
      onTap: url.isEmpty
          ? null
          : () {
              launchUrlString(url);
            },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: previewSize,
        constraints: BoxConstraints(
          minHeight: isImage ? previewSize : 68,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isImage ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _AttachmentThumbnail(url: url),
              )
            else
              Icon(
                Icons.insert_drive_file_outlined,
                size: 28,
                color: colors.onSurfaceVariant,
              ),
            const SizedBox(height: 8),
            Text(
              filename,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            if (!isImage && (type != null || sizeBytes != null))
              Text(
                [
                  if (type != null) type!,
                  if (sizeBytes != null) _formatSize(sizeBytes!),
                ].join(' • '),
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  bool _isImage(String? mime, String name) {
    if (mime != null && mime.startsWith('image/')) return true;
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  final String url;

  const _AttachmentThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return _placeholder(context);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: 60,
      fit: BoxFit.cover,
      errorWidget: (context, url, error) => _placeholder(context),
      placeholder: (context, url) => Container(
        height: 60,
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ThreadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRetry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
