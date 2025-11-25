import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../services/notification_service.dart';
import 'compose_screen.dart';
import 'domains_screen.dart';
import 'message_detail_screen.dart';
import 'profile_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  String?
      _selectedFolder; // null means default (inbox usually, or whatever api defaults to)
  bool? _isStarredFilter; // true if filtering by starred
  StreamSubscription<String>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to notification taps
    _notificationSubscription =
        NotificationService.notificationTapStream.listen((messageId) {
      _handleNotificationTap(messageId);
    });

    // Defer the initial load until after the first frame to ensure context is available
    // and to avoid conflicts with the provider's initial state if needed.
    // However, ApiClient might already be bootstrapping.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshMessages();
      final client = Provider.of<ApiClient>(context, listen: false);
      if (!client.mailBootstrapped && !client.isBootstrappingMail) {
        client.bootstrapMail();
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _handleNotificationTap(String messageId) {
    // Find the message in the current list
    final client = Provider.of<ApiClient>(context, listen: false);
    final message = client.messages.firstWhere(
      (m) => m['id'].toString() == messageId,
      orElse: () => <String, dynamic>{},
    );

    if (message.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MessageDetailScreen(message: message),
        ),
      );
    }
  }

  Future<void> _refreshMessages() async {
    await context.read<ApiClient>().loadMessages(
          force: true,
          folder: _selectedFolder,
          isStarred: _isStarredFilter,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiClient>(
      builder: (context, client, child) {
        return Scaffold(
          appBar: _isSelectionMode
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _deselectAll,
                  ),
                  title: Text('${_selectedIds.length} selected'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: () => _selectAll(client.messages),
                      tooltip: 'Select All',
                    ),
                    IconButton(
                      icon: const Icon(Icons.mark_email_read),
                      onPressed: () => _performBulkAction(
                          client, (id) => client.updateMessageStatus(id, true)),
                      tooltip: 'Mark as Read',
                    ),
                    IconButton(
                      icon: const Icon(Icons.mark_email_unread),
                      onPressed: () => _performBulkAction(client,
                          (id) => client.updateMessageStatus(id, false)),
                      tooltip: 'Mark as Unread',
                    ),
                    if (_selectedFolder == 'trash')
                      IconButton(
                        icon: const Icon(Icons.restore_from_trash),
                        onPressed: () => _performBulkAction(client,
                            (id) => client.moveMessageToFolder(id, 'inbox')),
                        tooltip: 'Restore',
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _performBulkAction(client,
                            (id) => client.moveMessageToFolder(id, 'trash')),
                        tooltip: 'Move to Bin',
                      ),
                  ],
                )
              : AppBar(
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
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      children: [
                        _DrawerSectionLabel(
                          title: 'Mailboxes',
                          subtitle: client.baseUrl != null
                              ? 'Connected to ${Uri.tryParse(client.baseUrl!)?.host ?? client.baseUrl!}'
                              : null,
                        ),
                        const SizedBox(height: 6),
                        _buildInboxTile(
                          context,
                          icon: Icons.inbox,
                          title: 'Inbox',
                          selected: _selectedFolder == 'inbox' &&
                              _isStarredFilter != true,
                          onTap: () {
                            setState(() {
                              _selectedFolder = 'inbox';
                              _isStarredFilter = null;
                            });
                            Navigator.pop(context);
                            _refreshMessages();
                          },
                        ),
                        _buildInboxTile(
                          context,
                          icon: Icons.star_border,
                          title: 'Starred',
                          selected: _isStarredFilter == true,
                          onTap: () {
                            setState(() {
                              _selectedFolder = null;
                              _isStarredFilter = true;
                            });
                            Navigator.pop(context);
                            _refreshMessages();
                          },
                        ),
                        _buildInboxTile(
                          context,
                          icon: Icons.send,
                          title: 'Sent',
                          selected: _selectedFolder == 'sent',
                          onTap: () {
                            setState(() {
                              _selectedFolder = 'sent';
                              _isStarredFilter = null;
                            });
                            Navigator.pop(context);
                            _refreshMessages();
                          },
                        ),
                        _buildInboxTile(
                          context,
                          icon: Icons.drafts,
                          title: 'Drafts',
                          selected: _selectedFolder == 'drafts',
                          onTap: () {
                            setState(() {
                              _selectedFolder = 'drafts';
                              _isStarredFilter = null;
                            });
                            Navigator.pop(context);
                            _refreshMessages();
                          },
                        ),
                        _buildInboxTile(
                          context,
                          icon: Icons.mail,
                          title: 'All Mail',
                          selected: _selectedFolder == null &&
                              _isStarredFilter != true &&
                              client.activeInboxId == null,
                          onTap: () async {
                            final wasSpecificInbox =
                                client.activeInboxId != null;
                            setState(() {
                              _selectedFolder = null;
                              _isStarredFilter = null;
                            });
                            Navigator.pop(context);
                            if (wasSpecificInbox) {
                              await client.setActiveInbox(null);
                            } else {
                              await _refreshMessages();
                            }
                          },
                        ),
                        _buildInboxTile(
                          context,
                          icon: Icons.report,
                          title: 'Spam',
                          selected: _selectedFolder == 'spam',
                          onTap: () {
                            setState(() {
                              _selectedFolder = 'spam';
                              _isStarredFilter = null;
                            });
                            Navigator.pop(context);
                            _refreshMessages();
                          },
                        ),
                        _buildInboxTile(
                          context,
                          icon: Icons.delete,
                          title: 'Bin',
                          selected: _selectedFolder == 'trash',
                          onTap: () {
                            setState(() {
                              _selectedFolder = 'trash';
                              _isStarredFilter = null;
                            });
                            Navigator.pop(context);
                            _refreshMessages();
                          },
                        ),
                        const Divider(height: 16),
                        if (inboxes.isNotEmpty) ...[
                          _DrawerSectionLabel(title: 'Inboxes'),
                          const SizedBox(height: 4),
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
                        ],
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
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
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
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
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
          final subject = (msg['subject'] as String?)?.trim().isNotEmpty == true
              ? msg['subject'] as String
              : '(No Subject)';
          final preview = msg['preview_text'] as String? ?? '';

          final isSelected = _selectedIds.contains(msg['id']);

          final isTrash = _selectedFolder == 'trash';
          return Dismissible(
            key: Key(msg['id']),
            background: Container(
              color: isTrash ? colors.tertiaryContainer : colors.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                isTrash ? Icons.restore_from_trash : Icons.delete,
                color: isTrash
                    ? colors.onTertiaryContainer
                    : colors.onErrorContainer,
              ),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              if (isTrash) {
                client.moveMessageToFolder(msg['id'], 'inbox');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restored to Inbox')),
                );
              } else {
                client.moveMessageToFolder(msg['id'], 'trash');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Moved to Bin'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        client.moveMessageToFolder(msg['id'], 'inbox');
                      },
                    ),
                  ),
                );
              }
            },
            child: ListTile(
              leading: isSelected
                  ? CircleAvatar(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      child: const Icon(Icons.check),
                    )
                  : CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: Text(initial),
                    ),
              title: Text(
                subject,
                style: TextStyle(
                  fontWeight: (msg['is_read'] as bool? ?? false)
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(msg['created_at']),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      if (!(msg['is_read'] as bool? ?? false))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          child: Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final newStatus = !(msg['is_starred'] == true);
                      context
                          .read<ApiClient>()
                          .starMessage(msg['id'], newStatus);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        (msg['is_starred'] == true)
                            ? Icons.star
                            : Icons.star_border,
                        color: (msg['is_starred'] == true)
                            ? Colors.amber
                            : colors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              selected: isSelected,
              onLongPress: () => _enterSelectionMode(msg['id'] as String),
              onTap: () {
                if (_isSelectionMode) {
                  _toggleSelection(msg['id'] as String);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessageDetailScreen(message: msg),
                    ),
                  );
                }
              },
            ),
          )
              .animate()
              .fade(duration: 400.ms, delay: (50 * index).ms)
              .slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }

  String _initial(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    // Convert UTC to IST (UTC+5:30)
    final date = DateTime.parse(dateStr)
        .toUtc()
        .add(const Duration(hours: 5, minutes: 30));
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _selectAll(List<Map<String, dynamic>> messages) {
    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(messages.map((m) => m['id'] as String));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _performBulkAction(
      ApiClient client, Future<bool> Function(String) action) async {
    final ids = _selectedIds.toList();
    _deselectAll(); // Exit mode immediately for better UX

    int successCount = 0;
    // Process in parallel
    await Future.wait(ids.map((id) async {
      if (await action(id)) {
        successCount++;
      }
    }));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated $successCount messages'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDrawerHeader(BuildContext context, ApiClient client) {
    final user = client.user;
    final colors = Theme.of(context).colorScheme;
    final name = (user?['displayName'] as String?) ??
        (user?['name'] as String?) ??
        (user?['username'] as String?) ??
        'Admin';
    final email = (user?['email'] as String?) ??
        (user?['username'] as String?) ??
        'admin';
    final avatarRaw =
        (user?['avatarUrl'] as String?) ?? (user?['avatar_url'] as String?);
    final avatarUrl = _resolveAvatarUrl(client.baseUrl, avatarRaw);
    final initials = _initial(name.isNotEmpty ? name : email);
    final role = (user?['role'] as String?)?.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onPrimaryContainer,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (role != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              colors.onPrimaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontSize: 10,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: selected
            ? colors.primaryContainer.withValues(alpha: 0.4)
            : colors.surfaceContainerHighest.withValues(alpha: 0.4),
        selectedTileColor: colors.primaryContainer.withValues(alpha: 0.6),
        selectedColor: colors.onPrimaryContainer,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected
                ? colors.primary.withValues(alpha: 0.15)
                : colors.surfaceVariant.withValues(alpha: 0.4),
          ),
          child: Icon(
            icon,
            size: 20,
            color: selected ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: selected
            ? Icon(Icons.check_circle, size: 20, color: colors.primary)
            : const Icon(Icons.chevron_right, size: 18),
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
            FilledButton(
                onPressed: () => onRetry(), child: const Text('Retry')),
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
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback,
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}
