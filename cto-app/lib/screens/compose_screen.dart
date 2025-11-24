import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;

  void _send() async {
    setState(() => _isLoading = true);
    final client = Provider.of<ApiClient>(context, listen: false);
    
    final toList = _toController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (toList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add recipient')));
      setState(() => _isLoading = false);
      return;
    }

    // Since we don't have 'from' selector yet, we might need to fetch user email or just let backend handle default if allowed.
    // The API requires 'from'.
    // We should probably fetch user profile to get the default email address.
    // For now, let's try to get it from a saved pref or assume the user knows their email.
    // Actually, let's just ask for 'From' or assume the first mailbox email.
    // Let's check mailboxes to find a valid 'from'.
    
    String from = '';
    try {
      final boxes = await client.getMailboxes();
      if (boxes.isNotEmpty && boxes[0]['email'] != null) {
        from = boxes[0]['email'];
      }
    } catch (e) {
      // ignore
    }

    if (from.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not determine sender address')));
        setState(() => _isLoading = false);
        return;
    }

    final success = await client.sendMessage(
      from: from,
      to: toList,
      subject: _subjectController.text,
      body: _bodyController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (success) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
      }
    }
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
                     decoration: const InputDecoration(hintText: 'e.g. Ask for a meeting on Friday'),
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
                   onPressed: loading ? null : () async {
                     setDialogState(() => loading = true);
                     final client = Provider.of<ApiClient>(context, listen: false);
                     final result = await client.generateEmail(promptController.text);
                     
                     if (result != null && mounted) {
                        setState(() {
                          _bodyController.text = result;
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
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
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
          children: [
             TextField(
               controller: _toController,
               decoration: const InputDecoration(
                 labelText: 'To',
                 hintText: 'email@example.com, ...'
               ),
             ),
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
                   border: InputBorder.none,
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
