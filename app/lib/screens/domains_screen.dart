import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';

class DomainsScreen extends StatefulWidget {
  const DomainsScreen({super.key});

  @override
  State<DomainsScreen> createState() => _DomainsScreenState();
}

class _DomainsScreenState extends State<DomainsScreen> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDomains());
  }

  Future<void> _loadDomains({bool force = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = Provider.of<ApiClient>(context, listen: false);
    try {
      await client.loadDomains(force: force);
    } catch (_) {
      _error = 'Unable to load domains';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domains'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : () => _loadDomains(force: true),
          ),
        ],
      ),
      body: Consumer<ApiClient>(
        builder: (context, client, child) {
          final domains = client.domains;

          if (_loading && domains.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null && domains.isEmpty) {
            return _errorView();
          }

          if (domains.isEmpty) {
            return _emptyState();
          }

          return RefreshIndicator(
            onRefresh: () => _loadDomains(force: true),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: domains.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final domain = domains[index];
                return ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(domain['domain'] as String? ?? ''),
                  subtitle: Text(
                    domain['created_at'] as String? ?? 'Pending verification',
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDomain(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(_error ?? ''),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _loadDomains(force: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.domain_add, size: 64),
            SizedBox(height: 16),
            Text('No domains yet'),
            SizedBox(height: 8),
            Text(
              'Add your first domain to start creating inboxes.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _addDomain(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Domain'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'example.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final domain = controller.text.trim();
              if (domain.isEmpty) return;
              final client = Provider.of<ApiClient>(context, listen: false);
              final success = await client.addDomain(domain);
              if (!context.mounted) return;
              if (success) {
                Navigator.pop(context);
                if (mounted) {
                  _loadDomains(force: true);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to add domain')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
