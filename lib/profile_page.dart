import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    // Mostrar picker cupertino en modal
    final now = DateTime.now();
    DateTime initial = _dob ?? DateTime(now.year - 30, 1, 1);
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => SizedBox(
        height: 260,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initial,
                maximumDate: DateTime.now(),
                minimumYear: 1900,
                maximumYear: now.year,
                onDateTimeChanged: (picked) {
                  setState(() => _dob = picked);
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Aceptar'),
              onPressed: () {
                if (_dob != null) {
                  dobController.text = _dob!.toLocal().toIso8601String().split('T').first;
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
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
        Navigator.push(context, CupertinoPageRoute(builder: (_) => const HomePage()));
        break;
      case 1:
        Navigator.push(context, CupertinoPageRoute(builder: (_) => const MessagesPage()));
        break;
      case 2:
        // already here
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

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
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

  Widget _cupertinoFieldWithIcon({required IconData icon, required Widget field}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: field),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? '';
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Perfil'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: _loading ? const CupertinoActivityIndicator() : const Icon(CupertinoIcons.power),
          onPressed: _loading ? null : _signOut,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Cupertino-styled scroll with pull-to-refresh
            CupertinoScrollbar(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Pull-to-refresh control (Cupertino style)
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      // Re-query Firestore and update state
                      await _loadUserData();
                    },
                  ),

                  // Main content as a single sliver
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Header
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(14),
                            ),
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
                                    Text(email, style: const TextStyle(color: CupertinoColors.inactiveGray)),
                                    const SizedBox(height: 8),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: Row(children: const [Icon(CupertinoIcons.camera, size: 18), SizedBox(width: 6), Text('Cambiar avatar')]),
                                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editar foto no implementado'))),
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Form area (cupertino style)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Información personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 12),

                                  // Nombre
                                  _cupertinoFieldWithIcon(
                                    icon: CupertinoIcons.person,
                                    field: CupertinoTextField(
                                      controller: nombreController,
                                      placeholder: 'Nombre completo',
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Teléfono
                                  _cupertinoFieldWithIcon(
                                    icon: CupertinoIcons.phone,
                                    field: CupertinoTextField(
                                      controller: telefonoController,
                                      keyboardType: TextInputType.phone,
                                      placeholder: 'Teléfono',
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Fecha de nacimiento (tap opens cupertino date picker)
                                  _cupertinoFieldWithIcon(
                                    icon: CupertinoIcons.calendar,
                                    field: GestureDetector(
                                      onTap: _pickDOB,
                                      child: AbsorbPointer(
                                        child: CupertinoTextField(
                                          controller: dobController,
                                          placeholder: 'Fecha de nacimiento',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Género (open action sheet)
                                  _cupertinoFieldWithIcon(
                                    icon: CupertinoIcons.person_2,
                                    field: GestureDetector(
                                      onTap: () {
                                        showCupertinoModalPopup(
                                          context: context,
                                          builder: (context) => CupertinoActionSheet(
                                            title: const Text('Selecciona género'),
                                            actions: _genders
                                                .map((g) => CupertinoActionSheetAction(
                                                      onPressed: () {
                                                        setState(() => _gender = g);
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text(g),
                                                    ))
                                                .toList(),
                                            cancelButton: CupertinoActionSheetAction(
                                              onPressed: () => Navigator.pop(context),
                                              isDestructiveAction: true,
                                              child: const Text('Cancelar'),
                                            ),
                                          ),
                                        );
                                      },
                                      child: AbsorbPointer(
                                        child: CupertinoTextField(
                                          controller: TextEditingController(text: _gender ?? ''),
                                          placeholder: 'Género',
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Enfermedades / notas
                                  Container(
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.all(8),
                                    child: CupertinoTextField(
                                      controller: enfermedadesController,
                                      maxLines: 4,
                                      placeholder: 'Enfermedades / alergias / notas',
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Buttons row (Cupertino)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CupertinoButton.filled(
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          onPressed: _loading ? null : _saveUserData,
                                          child: _loading ? const CupertinoActivityIndicator() : const Text('Guardar'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      CupertinoButton(
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        onPressed: _loading
                                            ? null
                                            : () {
                                                _loadUserData();
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurado a valores guardados')));
                                              },
                                        child: const Text('Restaurar'),
                                        color: null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Extra info
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(CupertinoIcons.info, color: Colors.teal),
                              title: const Text('Privacidad y datos'),
                              subtitle: const Text('Tus datos personales se almacenan en Firestore bajo tu cuenta.'),
                              trailing: const Icon(CupertinoIcons.forward),
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ver política de privacidad'))),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading overlay
            if (_loading)
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.systemGrey.withOpacity(0.25),
                  child: const Center(child: CupertinoActivityIndicator(radius: 16)),
                ),
              ),

            // Bottom tab bar positioned over the content
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: CupertinoTabBar(
                  currentIndex: _selectedIndex,
                  onTap: _onNavTap,
                  activeColor: Colors.teal,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Inicio'),
                    BottomNavigationBarItem(icon: Icon(CupertinoIcons.conversation_bubble), label: 'Mensajes'),
                    BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'Configuración'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
