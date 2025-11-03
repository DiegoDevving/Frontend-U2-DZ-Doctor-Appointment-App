import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';
import 'home_page.dart';
import 'messages_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController enfermedadesController = TextEditingController();

  // Nuevos campos: fecha de nacimiento y género
  final TextEditingController dobController = TextEditingController();
  DateTime? _dob;
  String? _gender;
  final List<String> _genders = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decir'];

  bool _loading = false;
  int _selectedIndex = 2; // perfil/ajustes (usar 2 para mantener consistencia)

  User? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _user;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        nombreController.text = data['nombre'] ?? user.displayName ?? '';
        telefonoController.text = data['telefono'] ?? '';
        enfermedadesController.text = data['enfermedades'] ?? '';

        // cargar fecha de nacimiento (puede ser Timestamp o String)
        final dobField = data['dob'];
        if (dobField != null) {
          if (dobField is Timestamp) {
            _dob = dobField.toDate();
          } else if (dobField is String) {
            _dob = DateTime.tryParse(dobField);
          }
          if (_dob != null) {
            dobController.text = _dob!.toLocal().toIso8601String().split('T').first;
          }
        }

        _gender = data['gender'] ?? '';
      } else {
        nombreController.text = user.displayName ?? (user.email?.split('@').first ?? '');
      }
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando datos: $e')));
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _user;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      await _firestore.collection('usuarios').doc(user.uid).set({
        'nombre': nombreController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'enfermedades': enfermedadesController.text.trim(),
        'uid': user.uid,
        'email': user.email,
        // Guardar dob como Timestamp si existe
        if (_dob != null) 'dob': Timestamp.fromDate(_dob!),
        'gender': _gender ?? '',
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos guardados correctamente')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando datos: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDOB() async {
    final initial = _dob ?? DateTime(1990, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        dobController.text = picked.toLocal().toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() => _loading = true);
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
        break;
    }
  }

  Widget _buildAvatar() {
    final displayName = nombreController.text.isNotEmpty
        ? nombreController.text
        : (_user?.displayName ?? _user?.email?.split('@').first ?? 'U');

    final initials = displayName.trim().isNotEmpty
        ? displayName.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 44,
      backgroundColor: Colors.teal.shade100,
      child: Text(initials, style: const TextStyle(fontSize: 28, color: Colors.teal)),
    );
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    enfermedadesController.dispose();
    dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: _loading ? null : _signOut,
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  children: [
                    // Header card with avatar and basic info
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _buildAvatar(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  nombreController.text.isNotEmpty ? nombreController.text : (_user?.displayName ?? 'Usuario'),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(email, style: const TextStyle(color: Colors.black54)),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editar foto no implementado'))),
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text('Cambiar avatar'),
                                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Form card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Información personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),

                              // Nombre
                              TextFormField(
                                controller: nombreController,
                                decoration: InputDecoration(
                                  labelText: 'Nombre completo',
                                  prefixIcon: const Icon(Icons.person),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 12),

                              // Teléfono
                              TextFormField(
                                controller: telefonoController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Teléfono',
                                  prefixIcon: const Icon(Icons.phone),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return null;
                                  final cleaned = v.replaceAll(RegExp(r'\D'), '');
                                  return cleaned.length < 7 ? 'Número no válido' : null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Fecha de nacimiento
                              TextFormField(
                                controller: dobController,
                                readOnly: true,
                                onTap: _pickDOB,
                                decoration: InputDecoration(
                                  labelText: 'Fecha de nacimiento',
                                  prefixIcon: const Icon(Icons.cake),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) {
                                  return null; // opcional
                                },
                              ),
                              const SizedBox(height: 12),

                              // Género
                              DropdownButtonFormField<String>(
                                value: (_gender != null && _gender!.isNotEmpty) ? _gender : null,
                                decoration: InputDecoration(
                                  labelText: 'Género',
                                  prefixIcon: const Icon(Icons.wc),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (v) => setState(() => _gender = v),
                              ),
                              const SizedBox(height: 12),

                              // Enfermedades / notas
                              TextFormField(
                                controller: enfermedadesController,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'Enfermedades / alergias / notas',
                                  prefixIcon: const Icon(Icons.note),
                                  alignLabelWithHint: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _loading ? null : _saveUserData,
                                      icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                                      label: const Text('Guardar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                            // reset form to last saved values by reloading
                                            _loadUserData();
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurado a valores guardados')));
                                          },
                                    child: const Text('Restaurar'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Extra info card
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.info_outline, color: Colors.teal),
                        title: const Text('Privacidad y datos'),
                        subtitle: const Text('Tus datos personales se almacenan en Firestore bajo tu cuenta.'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ver política de privacidad'))),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Loading overlay
              if (_loading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.25),
                    child: const Center(child: CircularProgressIndicator(color: Colors.teal)),
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