import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import 'package:intl/intl.dart';

class MessageDetailScreen extends StatelessWidget {
  final Map<String, dynamic> message;

  const MessageDetailScreen({super.key, required this.message});

  void _summarize(BuildContext context) async {
    final client = Provider.of<ApiClient>(context, listen: false);
    final body = message['body_plain'] ?? message['body_html'] ?? '';
    
    if (body.isEmpty) return;

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
               content: SingleChildScrollView(child: Text(snapshot.data ?? 'Failed to summarize')),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(context),
                   child: const Text('Close'),
                 )
               ],
             );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = message['created_at'];
    final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(''), // Empty title
        actions: [
           IconButton(
             icon: const Icon(Icons.summarize),
             onPressed: () => _summarize(context),
             tooltip: 'Summarize',
           ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['subject'] ?? '(No Subject)',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                   child: Text((message['sender_email'] ?? '?').substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message['sender_email'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (date != null)
                        Text(DateFormat.yMMMd().add_jm().format(date), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              message['body_plain'] ?? message['body_html'] ?? '',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
