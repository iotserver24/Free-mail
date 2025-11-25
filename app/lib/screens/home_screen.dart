import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import 'compose_screen.dart';
import 'domains_screen.dart';
import 'message_detail_screen.dart';
import 'profile_screen.dart';

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
    final inboxes = client.inboxes;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context, client),
            Expanded(
              child: client.isBootstrappingMail && inboxes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        _DrawerSectionLabel(
                          title: 'Mailboxes',
                          subtitle: client.baseUrl != null
                              ? 'Connected to ${Uri.tryParse(client.baseUrl!)?.host ?? client.baseUrl!}'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInboxTile(
                          context,
                          icon: Icons.all_inbox_outlined,
                          title: 'All mail',
                          subtitle: 'Everything in one view',
                          selected: client.activeInboxId == null,
                          onTap: () {
                            Navigator.pop(context);
                            client.setActiveInbox(null);
                          },
                        ),
                        ...inboxes.map(
                          (inbox) {
                            final name = inbox['name'] as String? ?? 'Inbox';
                            final email = inbox['email'] as String?;
                            return _buildInboxTile(
                              context,
                              icon: Icons.mark_email_read_outlined,
                              title: name,
                              subtitle: email,
                              selected: client.activeInboxId == inbox['id'],
                              onTap: () {
                                Navigator.pop(context);
                                client.setActiveInbox(inbox['id'] as String?);
                              },
                            );
                          },
                        ),
                        if (inboxes.isEmpty && client.mailBootstrapped) ...[
                          const SizedBox(height: 16),
                          _InlineHintCard(
                            icon: Icons.add_circle_outline,
                            message:
                                'No personalized inboxes yet. Ask your admin to assign you one.',
                          ),
                        ],
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Profile & settings'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      client.logout();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ],
              ),
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

  Widget _buildDrawerHeader(BuildContext context, ApiClient client) {
    final user = client.user;
    final colors = Theme.of(context).colorScheme;
    final name = (user?['displayName'] as String?) ??
        (user?['name'] as String?) ??
        (user?['username'] as String?) ??
        'Admin';
    final email =
        (user?['email'] as String?) ?? (user?['username'] as String?) ?? 'admin';
    final avatarRaw =
        (user?['avatarUrl'] as String?) ?? (user?['avatar_url'] as String?);
    final avatarUrl = _resolveAvatarUrl(client.baseUrl, avatarRaw);
    final initials = _initial(name.isNotEmpty ? name : email);
    final role = (user?['role'] as String?)?.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              colors.primaryContainer,
              colors.primaryContainer.withValues(alpha: 0.75),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProfileAvatar(
              imageUrl: avatarUrl,
              fallbackInitials: initials,
              colorScheme: colors,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              colors.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (role != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 12,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInboxTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: selected
            ? colors.primaryContainer.withValues(alpha: 0.4)
            : colors.surfaceContainerHighest.withValues(alpha: 0.4),
        selectedTileColor: colors.primaryContainer.withValues(alpha: 0.6),
        selectedColor: colors.onPrimaryContainer,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? colors.primary.withValues(alpha: 0.15)
                : colors.surfaceVariant.withValues(alpha: 0.4),
          ),
          child: Icon(
            icon,
            color: selected ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: selected
            ? Icon(Icons.check_circle, color: colors.primary)
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String? _resolveAvatarUrl(String? baseUrl, String? avatarPath) {
    if (avatarPath == null || avatarPath.trim().isEmpty) return null;
    final trimmed = avatarPath.trim();
    if (trimmed.startsWith('http')) {
      return trimmed;
    }
    if (baseUrl == null || baseUrl.isEmpty) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return '$baseUrl/$trimmed';
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

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
            letterSpacing: 0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _InlineHintCard extends StatelessWidget {
  const _InlineHintCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.fallbackInitials,
    required this.colorScheme,
  });

  final String? imageUrl;
  final String fallbackInitials;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: 32,
      backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
      child: Text(
        fallbackInitials,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );

    if (imageUrl == null) return fallback;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
