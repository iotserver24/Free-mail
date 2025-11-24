import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/email_message.dart';
import 'package:intl/intl.dart';

class EmailDetailScreen extends StatelessWidget {
  final EmailMessage email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.reply),
            onPressed: () {
              // TODO: Reply
            },
          ),
          IconButton(
            icon: const Icon(Icons.reply_all),
            onPressed: () {
              // TODO: Reply all
            },
          ),
          IconButton(
            icon: const Icon(Icons.forward),
            onPressed: () {
              // TODO: Forward
            },
          ),
          IconButton(
            icon: Icon(
              email.isStarred ? Icons.star : Icons.star_border,
              color: email.isStarred ? Colors.amber : null,
            ),
            onPressed: () {
              // TODO: Toggle star
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mark_unread',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_unread),
                    SizedBox(width: 8),
                    Text('Mark as unread'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              // TODO: Handle actions
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subject
          Text(
            email.subject,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Sender info
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                radius: 24,
                child: Text(
                  email.senderName.isNotEmpty 
                      ? email.senderName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.senderName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      email.senderEmail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                dateFormat.format(email.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Recipients
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'to ${email.to}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (email.cc != null && email.cc!.isNotEmpty)
                  Text(
                    'cc ${email.cc!.join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 32),
          
          // Body
          Html(
            data: email.body,
            onLinkTap: (url, _, __) {
              if (url != null) {
                launchUrl(Uri.parse(url));
              }
            },
          ),
          
          // Attachments
          if (email.attachments != null && email.attachments!.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'Attachments (${email.attachments!.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...email.attachments!.map((attachment) {
              return Card(
                child: ListTile(
                  leading: Icon(
                    attachment.isImage
                        ? Icons.image
                        : attachment.isPdf
                            ? Icons.picture_as_pdf
                            : Icons.attach_file,
                  ),
                  title: Text(attachment.filename),
                  subtitle: Text(attachment.sizeString),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      if (attachment.url != null) {
                        launchUrl(Uri.parse(attachment.url!));
                      }
                    },
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
