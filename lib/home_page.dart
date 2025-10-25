import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'messages_page.dart';
import 'settings_page.dart';
import 'citas_page.dart';
import 'routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  String get _userName {
    final user = _auth.currentUser;
    if (user == null) return 'Usuario';
    return user.displayName ??
        (user.email != null ? user.email!.split('@').first : 'Usuario');
  }

  final List<String> _specialties = [
    'Cardiología',
    'Dermatología',
    'Pediatría',
    'Neurología',
    'Ortopedia',
  ];

  final List<String> _medicalTips = [
    'Descansar la zona afectada y evitar movimientos bruscos.',
    'Aplicar frío',
    'Tomar analgésicos',
    'Consultar con un profesional si el dolor empeora o persiste.',
  ];

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        break; // Inicio
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessagesPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsPage()),
        );
        break;
    }
  }

  void _showTipsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) => ListTile(
            leading: const Icon(Icons.health_and_safety),
            title: Text(_medicalTips[i]),
          ),
          separatorBuilder: (_, __) => const Divider(),
          itemCount: _medicalTips.length,
        ),
      ),
    );
  }

  // NUEVO: Navegación a la pantalla de Citas
  void _goToCitasPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitasPage()),
    );
  }

  // NUEVO: Cerrar sesión
  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú principal'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Hola, $_userName! ¿En qué podemos ayudarte?',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: _goToCitasPage, // 🔄 reemplaza el placeholder anterior
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.calendar_today, size: 36),
                            SizedBox(height: 8),
                            Text('Gestionar Citas', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: _showTipsSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.medical_services, size: 36),
                            SizedBox(height: 8),
                            Text('Consejos médicos', textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Especialidades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _specialties.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final name = _specialties[index];
                  return SizedBox(
                    width: 140,
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
        ],
      ),
    );
  }
}
