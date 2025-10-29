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
  bool _signingOut = false;

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
        break; // stay on home
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, i) => ListTile(
            leading: const Icon(Icons.health_and_safety, color: Colors.teal),
            title: Text(_medicalTips[i]),
          ),
          separatorBuilder: (_, __) => const Divider(),
          itemCount: _medicalTips.length,
        ),
      ),
    );
  }

  void _goToCitasPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CitasPage()),
    );
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  Widget _headerCard() {
    final user = _auth.currentUser;
    final email = user?.email ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade100, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: user?.photoURL != null
                ? ClipOval(
                    child: Image.network(user!.photoURL!, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.teal)),
                  )
                : const Icon(Icons.person, color: Colors.teal, size: 36),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('¡Hola, $_userName!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ]),
          ),
          ElevatedButton.icon(
            onPressed: _signingOut ? null : _signOut,
            icon: _signingOut ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.logout),
            label: const Text('Salir'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(color: color ?? Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: 34, color: Colors.teal.shade800),
              ),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specialtyCard(String name) {
    return SizedBox(
      width: 140,
      child: Card(
        color: Colors.teal.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú principal'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.teal,
        elevation: 0,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _headerCard(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      const Text('¿En qué podemos ayudarte?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: _actionCard(icon: Icons.calendar_today, label: 'Gestionar Citas', onTap: _goToCitasPage)),
                          const SizedBox(width: 12),
                          Expanded(child: _actionCard(icon: Icons.medical_services, label: 'Consejos médicos', onTap: _showTipsSheet)),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text('Especialidades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _specialties.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) => _specialtyCard(_specialties[index]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                                  Text('Resumen', style: TextStyle(fontWeight: FontWeight.bold)),
                                  SizedBox(height: 6),
                                  Text('Atajos rápidos, citas próximas y notificaciones se mostrarán aquí.', style: TextStyle(color: Colors.black54)),
                                ]),
                              ),
                              ElevatedButton(
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ver resumen'))),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                child: const Text('Ver'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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