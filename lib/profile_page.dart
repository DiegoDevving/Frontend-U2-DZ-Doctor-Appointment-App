import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controladores de los campos del formulario
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController enfermedadesController = TextEditingController();

  bool _loading = false;
  //Loading es un interrutor visual
  // true -> muestra un "Cargando..."" y bloquea la ui
  //false -> muestra la ui normal

  @override
  void initState() {
    super.initState();
    _loadUserData();
  } // Aqui creamos la clase que cargara los datos del usuario al iniciar

  // Cargar datos del usuario desde Firestore
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('usuarios').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      nombreController.text = data['nombre'] ?? '';
      telefonoController.text = data['telefono'] ?? '';
      enfermedadesController.text = data['enfermedades'] ?? '';
    }
  }
  // Guardar datos del usuario en Firestore
  Future<void> _saveUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _loading = true;
    });

    await _firestore.collection('usuarios').doc(user.uid).set({
      'nombre': nombreController.text.trim(),
      'telefono': telefonoController.text.trim(),
      'enfermedades': enfermedadesController.text.trim(), //Nuevo (antes de historial medico)
      'uid': user.uid,
    });

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Datos guardados correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final FirebaseAuth _auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Nombre: Diego Zavaleta',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            //Boton para cerrar sesión
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Cerrar sesión'),
            ),

            //Boton para volver al menú principal
              ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Volver al Menú'),
              ),

              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}