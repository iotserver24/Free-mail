import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';

class ComposeDialog extends StatefulWidget {
  final VoidCallback? onSent;

  const ComposeDialog({super.key, this.onSent});

  @override
  State<ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<ComposeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  bool _isLoading = false;
  bool _showCc = false;
  bool _showBcc = false;

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final backendUrl = await authService.getBackendUrl();
      
      if (backendUrl == null) {
        throw Exception('Backend URL not found');
      }

      final emailService = EmailService(backendUrl);
      
      final success = await emailService.sendEmail(
        from: 'admin@example.com', // TODO: Get from user's email addresses
        to: _toController.text.trim(),
        subject: _subjectController.text.trim(),
        body: _bodyController.text,
        cc: _showCc && _ccController.text.isNotEmpty
            ? _ccController.text.split(',').map((e) => e.trim()).toList()
            : null,
        bcc: _showBcc && _bccController.text.isNotEmpty
            ? _bccController.text.split(',').map((e) => e.trim()).toList()
            : null,
      );

      if (!mounted) return;

      if (success) {
        widget.onSent?.call();
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send email')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Compose',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // To field
                    TextFormField(
                      controller: _toController,
                      decoration: InputDecoration(
                        labelText: 'To',
                        hintText: 'recipient@example.com',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showCc = !_showCc;
                                });
                              },
                              child: const Text('Cc'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showBcc = !_showBcc;
                                });
                              },
                              child: const Text('Bcc'),
                            ),
                          ],
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter recipient email';
                        }
                        return null;
                      },
                    ),
                    
                    // Cc field
                    if (_showCc)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextFormField(
                          controller: _ccController,
                          decoration: const InputDecoration(
                            labelText: 'Cc',
                            hintText: 'cc@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    
                    // Bcc field
                    if (_showBcc)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextFormField(
                          controller: _bccController,
                          decoration: const InputDecoration(
                            labelText: 'Bcc',
                            hintText: 'bcc@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Subject field
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter subject';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Body field
                    TextFormField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter message';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _handleSend,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
