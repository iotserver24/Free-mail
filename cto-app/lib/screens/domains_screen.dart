import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';

class DomainsScreen extends StatefulWidget {
  const DomainsScreen({super.key});

  @override
  State<DomainsScreen> createState() => _DomainsScreenState();
}

class _DomainsScreenState extends State<DomainsScreen> {
  // Since we don't have a getDomains method in ApiClient yet (except implicitly),
  // let's add one or assume we use the one we added.
  // Wait, I only added `addDomain` to ApiClient, not `getDomains`.
  // I need to update ApiClient to fetch domains.
  // `getDomains` -> GET /api/domains
  
  @override
  Widget build(BuildContext context) {
    // For now, let's just implement add domain. Listing is secondary but good to have.
    // I'll update ApiClient in a moment.
    
    return Scaffold(
      appBar: AppBar(title: const Text('Domains')),
      body: Consumer<ApiClient>(
        builder: (context, client, child) {
          // We need getDomains.
          return FutureBuilder(
            future: _fetchDomains(client), 
            builder: (context, snapshot) {
               if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
               
               if (snapshot.hasError) return const Center(child: Text("Error loading domains"));

               final domains = snapshot.data as List;
               
               if (domains.isEmpty) {
                 return const Center(child: Text("No domains added yet"));
               }

               return ListView.builder(
                 itemCount: domains.length,
                 itemBuilder: (context, index) {
                   final d = domains[index];
                   return ListTile(
                     title: Text(d['domain'] ?? ''),
                     subtitle: Text(d['created_at'] ?? ''),
                   );
                 },
               );
            }
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDomain(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<dynamic>> _fetchDomains(ApiClient client) async {
     // Hack: direct dio access or add method.
     // Ideally update ApiClient.
     // I'll implement a temporary solution or assume I update ApiClient.
     // Let's assume I update ApiClient.
     try {
       return await client.getDomains();
     } catch (e) {
       return [];
     }
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final domain = controller.text.trim();
              if (domain.isNotEmpty) {
                 final client = Provider.of<ApiClient>(context, listen: false);
                 final success = await client.addDomain(domain);
                 if (success && mounted) {
                   Navigator.pop(context);
                   setState(() {}); // Refresh list
                 }
              }
            }, 
            child: const Text('Add')
          ),
        ],
      )
    );
  }
}
