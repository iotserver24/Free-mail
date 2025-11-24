import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import 'compose_screen.dart';
import 'domains_screen.dart';
import 'message_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final client = Provider.of<ApiClient>(context, listen: false);
      if (!client.mailBootstrapped && !client.isBootstrappingMail) {
        client.bootstrapMail();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiClient>(
      builder: (context, client, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(client.activeInboxTitle),
            actions: [
              IconButton(
                icon: client.isBootstrappingMail
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: client.isBootstrappingMail
                    ? null
                    : () {
                        client.refreshMail();
                      },
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: implement search/filter
                },
              ),
            ],
          ),
          drawer: _buildDrawer(context, client),
          body: _buildBody(context, client),
          floatingActionButton: client.mailBootstrapped
              ? FloatingActionButton(
                  onPressed: client.activeFromAddress == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ComposeScreen(),
                            ),
                          );
                        },
                  child: const Icon(Icons.edit),
                )
              : null,
        );
      },
    );
  }

  Drawer _buildDrawer(BuildContext context, ApiClient client) {
    final user = client.user;
    final inboxes = client.inboxes;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?['name'] as String? ?? 'Admin'),
              accountEmail: Text(user?['email'] as String? ?? 'admin'),
              currentAccountPicture: CircleAvatar(
                child: Text(_initial(
                    user?['name'] as String? ?? user?['email'] as String? ?? 'F')),
              ),
            ),
            Expanded(
              child: client.isBootstrappingMail && inboxes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.inbox),
                          title: const Text('All Mail'),
                          selected: client.activeInboxId == null,
                          onTap: () {
                            Navigator.pop(context);
                            client.setActiveInbox(null);
                          },
                        ),
                        ...inboxes.map((inbox) {
                          final name = inbox['name'] as String? ?? 'Inbox';
                          final email = inbox['email'] as String?;
                          return ListTile(
                            leading: const Icon(Icons.mail_outline),
                            title: Text(name),
                            subtitle: email != null ? Text(email) : null,
                            selected: client.activeInboxId == inbox['id'],
                            onTap: () {
                              Navigator.pop(context);
                              client.setActiveInbox(inbox['id'] as String?);
                            },
                          );
                        }).toList(),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.domain),
                          title: const Text('Domains'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DomainsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                client.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ApiClient client) {
    if (client.mailError != null && client.messages.isEmpty) {
      return _ErrorState(
        message: client.mailError!,
        onRetry: client.refreshMail,
      );
    }

    if (!client.mailBootstrapped && client.isBootstrappingMail) {
      return const Center(child: CircularProgressIndicator());
    }

    if (client.loadingMessages && client.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (client.mailBootstrapped &&
        client.messages.isEmpty &&
        client.inboxes.isEmpty) {
      return _EmptyMailboxState(
        onAddDomain: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DomainsScreen()),
          );
        },
      );
    }

    if (client.messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: client.refreshMessages,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.mail_outline, size: 64),
            SizedBox(height: 16),
            Center(child: Text('No messages yet')),
          ],
        ),
      );
    }

    final messages = client.messages;
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: client.refreshMessages,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final sender =
              (msg['sender_email'] as String?)?.trim().isNotEmpty == true
                  ? (msg['sender_email'] as String)
                  : 'Unknown';
          final initial = _initial(sender);
          final subject =
              (msg['subject'] as String?)?.trim().isNotEmpty == true
                  ? msg['subject'] as String
                  : '(No Subject)';
          final preview = msg['preview_text'] as String? ?? '';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(initial),
            ),
            title: Text(
              subject,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender,
                  style: TextStyle(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (preview.isNotEmpty)
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageDetailScreen(message: msg),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => onRetry(), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyMailboxState extends StatelessWidget {
  final VoidCallback onAddDomain;

  const _EmptyMailboxState({required this.onAddDomain});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 72),
            const SizedBox(height: 16),
            Text(
              'Connect a domain to start receiving mail.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAddDomain,
              icon: const Icon(Icons.domain_add),
              label: const Text('Add domain'),
            ),
          ],
        ),
      ),
    );
  }
}
