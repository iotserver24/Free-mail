import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import 'compose_screen.dart';
import 'message_detail_screen.dart';
import 'domains_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedInboxId;
  String _selectedInboxName = "All Mail";
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedInboxName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
             icon: const Icon(Icons.search),
             onPressed: () {
               // TODO: Search
             },
          )
        ],
      ),
      drawer: Drawer(
        child: Consumer<ApiClient>(
          builder: (context, client, child) {
            return FutureBuilder(
              future: client.getMailboxes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final mailboxes = snapshot.data as List;
                return ListView(
                  children: [
                    const UserAccountsDrawerHeader(
                      accountName: Text("Admin"),
                      accountEmail: Text("admin@example.com"), 
                      currentAccountPicture: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.inbox),
                      title: const Text('All Mail'),
                      selected: _selectedInboxId == null,
                      onTap: () {
                        setState(() {
                          _selectedInboxId = null;
                          _selectedInboxName = "All Mail";
                        });
                        Navigator.pop(context);
                      },
                    ),
                    ...mailboxes.map((mb) {
                       return ListTile(
                         leading: const Icon(Icons.mail_outline),
                         title: Text(mb['name'] ?? 'Inbox'),
                         selected: _selectedInboxId == mb['id'],
                         onTap: () {
                           setState(() {
                             _selectedInboxId = mb['id'];
                             _selectedInboxName = mb['name'] ?? 'Inbox';
                           });
                           Navigator.pop(context);
                         },
                       );
                    }).toList(),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.domain),
                      title: const Text('Domains'),
                      onTap: () {
                         Navigator.pop(context);
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const DomainsScreen()));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Logout'),
                      onTap: () {
                        client.logout();
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: Consumer<ApiClient>(
        builder: (context, client, child) {
          return FutureBuilder(
            future: client.getMessages(_selectedInboxId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final messages = snapshot.data as List;
              if (messages.isEmpty) {
                return const Center(child: Text('No messages'));
              }

              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  // Basic Gmail-like list item
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text((msg['sender_email'] ?? '?').substring(0, 1).toUpperCase()),
                    ),
                    title: Text(
                      msg['subject'] ?? '(No Subject)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['sender_email'] ?? 'Unknown',
                          style: TextStyle(color: Colors.grey.shade700),
                          maxLines: 1,
                        ),
                        Text(
                          msg['preview_text'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => MessageDetailScreen(message: msg),
                      ));
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ComposeScreen()));
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
