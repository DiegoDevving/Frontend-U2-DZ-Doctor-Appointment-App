import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
      ),
      body: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final convo = _conversations[index];
          return ListTile(
            leading: const CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage('assets/images/avatar.png'),
            ),
            title: Text(convo['name']!),
            subtitle: Text(convo['preview']!),
            trailing: Text(convo['time']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            onTap: null, // sin interacción por ahora
          );
        },
      ),
    );
  }
}