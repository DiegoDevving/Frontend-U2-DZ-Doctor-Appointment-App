import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'routes.dart';
import 'home_page.dart';
import 'messages_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 2; // settings tab
  bool _signingOut = false;

  Future<void> _signOut(BuildContext context) async {
    setState(() => _signingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

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
        // already in settings
        break;
    }
  }

  Widget _buildTile({required IconData icon, required String title, required VoidCallback onTap, String? subtitle, Color? color}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color ?? Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.teal.shade800),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              // swipe right -> go to MessagesPage
              if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MessagesPage()));
              }
            },
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.settings, color: Colors.teal, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Ajustes de la aplicación', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferencias sincronizadas'))),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Sincronizar'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Tiles
                _buildTile(
                  icon: Icons.person,
                  title: 'Perfil',
                  subtitle: 'Editar información personal',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                ),
                _buildTile(
                  icon: Icons.lock,
                  title: 'Privacidad',
                  subtitle: 'Configuración de permisos y datos',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Privacidad'), backgroundColor: Colors.teal),
                        body: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Política de privacidad: Esta es una aplicación de ejemplo. '
                            'No se recopilan datos reales en esta versión demo.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildTile(
                  icon: Icons.info,
                  title: 'Sobre nosotros',
                  subtitle: 'Versión y detalles de la aplicación',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Sobre nosotros'), backgroundColor: Colors.teal),
                        body: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Acerca de la app: Demo de gestión de citas médicas y mensajes. '
                            'Versión de prueba sin funcionalidades completas.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Sign out button in a card at bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Cerrar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _signingOut ? null : () => _signOut(context),
                            icon: _signingOut ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.exit_to_app),
                            label: const Text('Salir'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
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