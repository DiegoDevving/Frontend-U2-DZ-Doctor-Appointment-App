import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  /// Nuevo: lista de roles disponibles
  final List<String> roles = ['doctor', 'paciente', 'administrador'];

  /// Nuevo: rol seleccionado
  String? selectedRole;

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación adicional del rol
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un rol')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      final username = usernameController.text.trim();

      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCred.user;
      if (user != null) {
        await _firestore.collection('usuarios').doc(user.uid).set({
          'username': username,
          'email': email,
          'uid': user.uid,
          'role': selectedRole,              // 🔥 Guarda el rol
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.updateDisplayName(username);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro exitoso')),
        );

        Navigator.pushReplacementNamed(context, Routes.home);
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Error en el registro';
      if (e.code == 'email-already-in-use') msg = 'El correo ya está en uso';
      if (e.code == 'weak-password') msg = 'Contraseña demasiado débil (mínimo 6 caracteres)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro - DoctorApp'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: usernameController,
                            decoration: _inputDecoration(label: 'Usuario', icon: Icons.person),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Ingresa un nombre de usuario' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(label: 'Correo electrónico', icon: Icons.email),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Por favor ingresa tu correo';
                              if (!v.contains('@') || !v.contains('.')) return 'Correo no válido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: _inputDecoration(label: 'Contraseña', icon: Icons.lock),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Por favor ingresa tu contraseña';
                              if (v.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          /// 🔥 NUEVO: Dropdown de roles
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration(label: 'Rol', icon: Icons.security),
                            value: selectedRole,
                            items: roles
                                .map((r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedRole = value);
                            },
                            validator: (v) =>
                                v == null ? 'Selecciona un rol' : null,
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ))
                                  : const Text('Crear cuenta'),
                            ),
                          ),

                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('¿Ya tienes cuenta? Iniciar sesión'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
