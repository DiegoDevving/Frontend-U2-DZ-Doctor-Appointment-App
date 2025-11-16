import 'package:flutter/material.dart';
import 'routes.dart';
import 'settings_page.dart';
import 'home_page.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _selectedIndex = 1; // messages tab
  String _search = '';

  final List<Map<String, String>> _conversations = const [
    {
      'name': 'Ana Torres',
      'preview': 'Hola, ¿cómo estás?',
      'time': '09:24'
    },
    {
      'name': 'Carlos Ruiz',
      'preview': '¿Puedes confirmar la cita?',
      'time': 'Ayer'
    },
    {
      'name': 'María López',
      'preview': 'Gracias por la información.',
      'time': 'lun'
    },
    {
      'name': 'Equipo Médico',
      'preview': 'Recordatorio: chequeo anual.',
      'time': 'dom'
    },
    {
      'name': 'Clínica Central',
      'preview': 'Tu resultado está listo.',
      'time': '15/10'
    },
  ];

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, Routes.home);
        break;
      case 1:
        // already on messages
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
        break;
    }
  }

  List<Map<String, String>> get _filteredConversations {
    if (_search.trim().isEmpty) return _conversations;
    final q = _search.toLowerCase();
    return _conversations.where((c) {
      return c['name']!.toLowerCase().contains(q) || c['preview']!.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildConversationTile(Map<String, String> convo) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.teal.shade50,
          child: ClipOval(
            child: Image.asset(
              'assets/images/avatar.png',
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: Colors.teal.shade700, size: 32),
            ),
          ),
        ),
        title: Text(convo['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(convo['preview']!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(convo['time']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
              child: const Text('1', style: TextStyle(fontSize: 12, color: Colors.teal)), // placeholder unread count
            ),
          ],
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Abrir chat con ${convo['name']}')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredConversations;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.teal),
                      hintText: 'Buscar conversaciones o mensajes',
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ),
            ),

            // Header / summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Conversaciones recientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${filtered.length}', style: TextStyle(color: Colors.teal.shade700)),
                ],
              ),
            ),

            // Conversations list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mark_chat_unread, size: 64, color: Colors.teal.shade100),
                          const SizedBox(height: 12),
                          const Text('No hay conversaciones', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildConversationTile(filtered[index]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nuevo mensaje'))),
        child: const Icon(Icons.edit),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ],
      ),
    );
  }
}