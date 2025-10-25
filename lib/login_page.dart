import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _loading = false;

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de sesión - DoctorApp'),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 28),
              child: Column(
                children: [
                  // Logo / icono médico centrado
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.local_hospital, size: 80, color: Colors.teal);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Card contenedor del formulario
                  ConstrainedBox(
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
                              // Correo
                              TextFormField(
                                controller: emailController,
                                decoration: _inputDecoration(label: "Correo electrónico", icon: Icons.email),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Por favor ingresa tu correo";
                                  }
                                  if (!value.contains("@") || !value.contains(".")) {
                                    return "Correo no válido";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Contraseña
                              TextFormField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: _inputDecoration(label: "Contraseña", icon: Icons.lock),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Por favor ingresa tu contraseña";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              // Botón Iniciar sesión
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    setState(() => _loading = true);
                                    try {
                                      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                                        email: emailController.text.trim(),
                                        password: passwordController.text.trim(),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Inicio de sesión exitoso ${userCredential.user?.email}")),
                                      );
                                      Navigator.pushReplacementNamed(context, Routes.home);
                                    } on FirebaseAuthException catch (e) {
                                      final msg = e.message ?? "Error de autenticación";
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                    } finally {
                                      if (mounted) setState(() => _loading = false);
                                    }
                                  },
                                  child: _loading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text("Iniciar sesión"),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Botón Cerrar sesión (estilo neutro)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[300],
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Sesión cerrada")),
                                    );
                                  },
                                  child: const Text("Cerrar sesión"),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Links: Olvidaste / Registrate (cada uno dentro de Expanded para evitar overflow)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        // UI only por ahora
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Recuperación de contraseña próximamente")),
                                        );
                                      },
                                      child: const Text("¿Olvidaste tu contraseña?"),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Registro próximamente")),
                                        );
                                      },
                                      child: const Text("¿No tienes cuenta? Regístrate aquí"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}