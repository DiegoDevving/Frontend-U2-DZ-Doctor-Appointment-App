import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitasPage extends StatefulWidget {
  const CitasPage({super.key});

  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController motivoController = TextEditingController();

  String? nombreUsuario;
  DateTime? fechaSeleccionada;
  String? citaEnEdicion; // ID de la cita que se está editando
  bool _loadingNombre = true;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  @override
  void dispose() {
    motivoController.dispose();
    super.dispose();
  }

  Future<void> _cargarNombreUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            nombreUsuario = doc.data()!['nombre'] ?? user.email?.split('@').first ?? 'Usuario';
          });
        } else {
          setState(() {
            nombreUsuario = user.email?.split('@').first ?? 'Usuario';
          });
        }
      } catch (_) {
        setState(() => nombreUsuario = user?.email?.split('@').first ?? 'Usuario');
      }
    }
    setState(() => _loadingNombre = false);
  }

  Future<void> _seleccionarFechaHora() async {
    final ahora = DateTime.now();
    final initial = fechaSeleccionada ?? ahora.add(const Duration(days: 1));
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: ahora,
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal)), child: child!),
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(fechaSeleccionada ?? initial),
      );

      if (pickedTime != null) {
        setState(() {
          fechaSeleccionada = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  Future<void> _guardarCita() async {
    if (motivoController.text.isEmpty || fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final data = {
      'nombreUsuario': nombreUsuario ?? user?.email?.split('@').first ?? 'Sin nombre',
      'motivo': motivoController.text.trim(),
      'fechaHora': Timestamp.fromDate(fechaSeleccionada!),
      'creadoEn': FieldValue.serverTimestamp(),
    };

    try {
      if (citaEnEdicion == null) {
        await _firestore.collection('citas').add(data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cita creada")));
      } else {
        await _firestore.collection('citas').doc(citaEnEdicion).update(data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cita actualizada")));
      }

      motivoController.clear();
      setState(() {
        fechaSeleccionada = null;
        citaEnEdicion = null;
      });

      Navigator.of(context).maybePop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _eliminarCita(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text('¿Eliminar esta cita? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      await _firestore.collection('citas').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cita eliminada")));
    }
  }

  void _editarCita(String id, Map<String, dynamic> data) {
    setState(() {
      citaEnEdicion = id;
      motivoController.text = data['motivo'] ?? '';
      fechaSeleccionada = (data['fechaHora'] as Timestamp?)?.toDate() ?? DateTime.now();
    });
    _openFormModal(title: 'Editar cita');
  }

  void _openFormModal({String title = 'Programar cita'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (citaEnEdicion != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              citaEnEdicion = null;
                              motivoController.clear();
                              fechaSeleccionada = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar edición'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: motivoController,
                    decoration: InputDecoration(
                      labelText: 'Motivo',
                      prefixIcon: const Icon(Icons.event_note),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _seleccionarFechaHora,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fechaSeleccionada == null ? 'Selecciona fecha y hora' : _formatDateTime(fechaSeleccionada!),
                              style: TextStyle(color: fechaSeleccionada == null ? Colors.black54 : Colors.teal.shade900),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.black38),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _guardarCita,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(citaEnEdicion == null ? 'Programar cita' : 'Guardar cambios'),
                        ),
                      ),
                      if (citaEnEdicion != null) const SizedBox(width: 12),
                      if (citaEnEdicion != null)
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              citaEnEdicion = null;
                              motivoController.clear();
                              fechaSeleccionada = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime dt) {
    final day = _twoDigits(dt.day);
    final month = _twoDigits(dt.month);
    final year = dt.year;
    final hour = _twoDigits(dt.hour);
    final minute = _twoDigits(dt.minute);
    // Formato: dd/mm/yyyy HH:MM
    return '$day/$month/$year $hour:$minute';
  }

  Widget _buildCitaCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final fecha = (data['fechaHora'] as Timestamp?)?.toDate();
    final fechaTexto = fecha != null ? _formatDateTime(fecha.toLocal()) : 'Sin fecha';
    final motivo = data['motivo'] ?? 'Sin motivo';
    final usuario = data['nombreUsuario'] ?? 'Desconocido';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.event_available, color: Colors.teal, size: 32),
        ),
        title: Text(motivo, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('$fechaTexto • $usuario', style: const TextStyle(color: Colors.black54)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editarCita(doc.id, data), tooltip: 'Editar'),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarCita(doc.id), tooltip: 'Eliminar'),
          ],
        ),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(motivo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Fecha: $fechaTexto', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text('Paciente: $usuario', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editarCita(doc.id, data);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _eliminarCita(doc.id);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade100)),
                      ),
                    ],
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citas'),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          motivoController.clear();
          fechaSeleccionada = null;
          citaEnEdicion = null;
          _openFormModal(title: 'Programar cita');
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva cita'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.calendar_today, color: Colors.teal, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(nombreUsuario ?? (_loadingNombre ? 'Cargando usuario...' : 'Usuario'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            const Text('Administra y programa tus citas médicas', style: TextStyle(color: Colors.black54)),
                          ]),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            motivoController.clear();
                            fechaSeleccionada = null;
                            citaEnEdicion = null;
                            _openFormModal();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: const Text('Programar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('citas').orderBy('fechaHora', descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: const [
                          Icon(Icons.event_busy, size: 64, color: Colors.teal),
                          SizedBox(height: 12),
                          Text('No hay citas programadas', style: TextStyle(color: Colors.black54)),
                        ]),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => _buildCitaCard(docs[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}