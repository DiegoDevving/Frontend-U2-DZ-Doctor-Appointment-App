import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Perfil', 'icon': Icons.person},
      {'title': 'Privacidad', 'icon': Icons.lock},
      {'title': 'Sobre nosotros', 'icon': Icons.info},
      {'title': 'Cerrar sesión', 'icon': Icons.exit_to_app},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: Icon(item['icon'] as IconData),
            title: Text(item['title'] as String),
            onTap: () {
              switch (index) {
                case 0: // Perfil
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                  break;
                case 1: // Privacidad
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Privacidad')),
                        body: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Política de privacidad: Esta es una aplicación de ejemplo. '
                            'No se recopilan datos reales en esta versión demo.',
                          ),
                        ),
                      ),
                    ),
                  );
                  break;
                case 2: // Sobre nosotros
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Sobre nosotros')),
                        body: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Acerca de la app: Demo de gestión de citas médicas y mensajes. '
                            'Versión de prueba sin funcionalidades completas.',
                          ),
                        ),
                      ),
                    ),
                  );
                  break;
                case 3: // Cerrar sesión
                  _signOut(context);
                  break;
              }
            },
          );
        },
      ),
    );
  }
}