import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../models/email_message.dart';
import '../widgets/email_list_item.dart';
import '../widgets/compose_dialog.dart';
import 'email_detail_screen.dart';
import 'settings_screen.dart';
import 'domains_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _folders = ['Inbox', 'Sent', 'Drafts', 'Trash'];
  int _selectedFolderIndex = 0;
  bool _isLoading = false;
  List<EmailMessage> _emails = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final backendUrl = await authService.getBackendUrl();
      
      if (backendUrl == null) {
        throw Exception('Backend URL not found');
      }

      final emailService = EmailService(backendUrl);
      final emails = await emailService.fetchEmails(
        folder: _folders[_selectedFolderIndex].toLowerCase(),
      );

      if (mounted) {
        setState(() {
          _emails = emails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final authService = context.read<AuthService>();
    await authService.logout();
    
    if (!mounted) return;
    
    // Navigate back to login
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showComposeDialog() {
    showDialog(
      context: context,
      builder: (context) => ComposeDialog(
        onSent: _loadEmails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freemail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.email,
                    size: 48,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Freemail',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(_folders.length, (index) {
              return ListTile(
                leading: Icon(_getFolderIcon(index)),
                title: Text(_folders[index]),
                selected: _selectedFolderIndex == index,
                onTap: () {
                  setState(() {
                    _selectedFolderIndex = index;
                  });
                  Navigator.pop(context);
                  _loadEmails();
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('Labels'),
              onTap: () {
                // TODO: Implement labels
              },
            ),
            ListTile(
              leading: const Icon(Icons.domain),
              title: const Text('Domains'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DomainsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmails,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showComposeDialog,
        icon: const Icon(Icons.edit),
        label: const Text('Compose'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _emails.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading emails',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_emails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${_folders[_selectedFolderIndex].toLowerCase()} is empty',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _emails.length,
      itemBuilder: (context, index) {
        final email = _emails[index];
        return EmailListItem(
          email: email,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmailDetailScreen(email: email),
              ),
            );
          },
        );
      },
    );
  }

  IconData _getFolderIcon(int index) {
    switch (index) {
      case 0:
        return Icons.inbox;
      case 1:
        return Icons.send;
      case 2:
        return Icons.drafts;
      case 3:
        return Icons.delete;
      default:
        return Icons.folder;
    }
  }
}
