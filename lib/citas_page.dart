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
  String estadoSeleccionado = 'pendiente';
  bool _loadingNombre = true;

  // NUEVO: lista de doctores obtenida de Firestore (id y nombre)
  List<Map<String, String>> _doctors = [];
  String? _selectedDoctorId;
  String? _selectedDoctorName;

  // NUEVO: duracion en minutos
  final List<int> _durations = [15, 30, 45, 60];
  int _selectedDuration = 30;

  // Usuario actual
  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String? _currentUserId;
  String? _currentUserRole; // 'doctor' | 'paciente' | 'administrador'

  @override
  void initState() {
    super.initState();
    _currentUserId = _currentUser?.uid;
    _loadCurrentUserRole();
    _cargarNombreUsuario();
    _loadDoctors();
  }

  @override
  void dispose() {
    motivoController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserRole() async {
    if (_currentUserId == null) return;
    try {
      final doc = await _firestore.collection('usuarios').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          // soporta 'role' o 'rol' según cómo lo hayas guardado
          _currentUserRole = (data['role'] ?? data['rol']) as String?;
        }
      }
    } catch (_) {
      // ignore
    }
    setState(() {});
  }

  Future<void> _loadDoctors() async {
    // Carga usuarios donde rol == 'doctor'
    try {
      final snap = await _firestore.collection('usuarios').where('rol', isEqualTo: 'doctor').get();
      final List<Map<String, String>> list = [];
      for (var d in snap.docs) {
        final data = d.data();
        final name = (data['nombre'] ?? data['username'] ?? data['displayName'])?.toString() ?? d.id;
        list.add({'id': d.id, 'name': name});
      }

      // Si no hay con 'rol', intenta con 'role' por compatibilidad
      if (list.isEmpty) {
        final snap2 = await _firestore.collection('usuarios').where('role', isEqualTo: 'doctor').get();
        for (var d in snap2.docs) {
          final data = d.data();
          final name = (data['nombre'] ?? data['username'] ?? data['displayName'])?.toString() ?? d.id;
          list.add({'id': d.id, 'name': name});
        }
      }

      setState(() {
        _doctors = list;
      });
    } catch (e) {
      // ignore errors - deja la lista vacía
    }
  }

  Future<void> _cargarNombreUsuario() async {
    final user = _currentUser;
    if (user != null) {
      try {
        final doc = await _firestore.collection('usuarios').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          setState(() {
            nombreUsuario = doc.data()!['nombre'] ?? doc.data()!['username'] ?? user.email?.split('@').first ?? 'Usuario';
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

  // Comprueba solapamientos para un doctor: retorna true si hay overlap
  Future<bool> _doctorHasOverlap(String doctorId, DateTime start, int durationMinutes, {String? excludingCitaId}) async {
    final end = start.add(Duration(minutes: durationMinutes));

    final snap = await _firestore
        .collection('citas')
        .where('doctorId', isEqualTo: doctorId)
        .get();

    for (var doc in snap.docs) {
      if (excludingCitaId != null && doc.id == excludingCitaId) continue;
      final data = doc.data();
      final Timestamp? ts = data['fechaHora'] as Timestamp?;
      if (ts == null) continue;
      final otherStart = ts.toDate();
      final otherDuration = (data['duration'] is int) ? (data['duration'] as int) : (data['duration'] is double ? (data['duration'] as double).toInt() : 30);
      final otherEnd = otherStart.add(Duration(minutes: otherDuration));

      // overlap check: start < otherEnd && otherStart < end
      if (start.isBefore(otherEnd) && otherStart.isBefore(end)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _guardarCita() async {
    // Validaciones básicas
    if (motivoController.text.isEmpty || fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos")));
      return;
    }
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona un doctor")));
      return;
    }

    // Permisos: si estamos editando, comprobar que el usuario tiene derecho
    if (citaEnEdicion != null) {
      // fetch cita to check ownership
      final citaDoc = await _firestore.collection('citas').doc(citaEnEdicion).get();
      if (citaDoc.exists) {
        final data = citaDoc.data()!;
        final ownerId = data['patientId'] ?? data['patientID'] ?? data['patient'] ?? data['uidPaciente'];
        // Si el usuario es paciente y no propietario, no permitir editar
        if (_currentUserRole == 'paciente' && ownerId != _currentUserId) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No puedes editar esta cita")));
          return;
        }
      }
    }

    // comprobación de disponibilidad (vuelve a verificar inmediatamente antes de crear/update)
    final start = fechaSeleccionada!;
    final duration = _selectedDuration;
    final conflict = await _doctorHasOverlap(_selectedDoctorId!, start, duration, excludingCitaId: citaEnEdicion);
    if (conflict) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El doctor ya tiene otra cita en ese horario. Elige otra hora o doctor.")));
      return;
    }

    final user = _currentUser;
    final data = {
      'nombreUsuario': nombreUsuario ?? user?.email?.split('@').first ?? 'Sin nombre',
      'patientId': _currentUserId,
      'patientName': nombreUsuario ?? 'Sin nombre',
      'doctorId': _selectedDoctorId,
      'doctorName': _selectedDoctorName ?? '',
      'motivo': motivoController.text.trim(),
      'fechaHora': Timestamp.fromDate(start),
      'creadoEn': FieldValue.serverTimestamp(),
      'estado': estadoSeleccionado,
      'duration': duration, // minutos
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
        estadoSeleccionado = 'pendiente';
        _selectedDuration = 30;
        _selectedDoctorId = null;
        _selectedDoctorName = null;
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

  // Cuando se solicita editar una cita: configura el modal con datos y permisos
  void _editarCita(String id, Map<String, dynamic> data) {
    // permisos: paciente solo puede editar su propia cita (para cancelar)
    final ownerId = data['patientId'] ?? data['patientID'] ?? data['patient'] ?? data['uidPaciente'];
    if (_currentUserRole == 'paciente' && ownerId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No puedes editar esta cita")));
      return;
    }

    // Cargar datos para edición
    setState(() {
      citaEnEdicion = id;
      motivoController.text = data['motivo'] ?? '';
      estadoSeleccionado = data['estado'] ?? 'pendiente';
      fechaSeleccionada = (data['fechaHora'] as Timestamp?)?.toDate();
      _selectedDuration = (data['duration'] is int) ? (data['duration'] as int) : (data['duration'] is double ? (data['duration'] as double).toInt() : 30);
      _selectedDoctorId = data['doctorId'] ?? null;
      _selectedDoctorName = data['doctorName'] ?? null;
    });

    _openFormModal(title: 'Editar cita');
  }

  // Modal con formulario: adapta campos editables según rol y si es edición
  void _openFormModal({String title = 'Programar cita'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        // determina permisos dentro del modal
        final bool isEditing = citaEnEdicion != null;
        final bool isPatient = _currentUserRole == 'paciente';
        final bool isDoctor = _currentUserRole == 'doctor';

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
                      if (isEditing)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              citaEnEdicion = null;
                              motivoController.clear();
                              fechaSeleccionada = null;
                              _selectedDoctorId = null;
                              _selectedDoctorName = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar edición'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Motivo (editable por propietario y por doctor)
                  TextField(
                    controller: motivoController,
                    readOnly: isPatient == false ? false : (isEditing ? false : false), // pacientes pueden escribir motivo al crear; al editar conservamos posibilidad de visualizar
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

                  // Dropdown para seleccionar doctor (si hay doctores cargados)
                  DropdownButtonFormField<String>(
                    value: _selectedDoctorId,
                    decoration: InputDecoration(
                      labelText: 'Doctor',
                      prefixIcon: const Icon(Icons.medical_services),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _doctors.map((d) => DropdownMenuItem(value: d['id'], child: Text(d['name'] ?? 'Doctor'))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDoctorId = value;
                        _selectedDoctorName = _doctors.firstWhere((e) => e['id'] == value)['name'];
                      });
                    },
                    validator: (_) => null,
                  ),

                  const SizedBox(height: 12),

                  // Duración
                  DropdownButtonFormField<int>(
                    value: _selectedDuration,
                    decoration: InputDecoration(
                      labelText: 'Duración (minutos)',
                      prefixIcon: const Icon(Icons.timer),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _durations.map((d) => DropdownMenuItem(value: d, child: Text('$d'))).toList(),
                    onChanged: (v) => setState(() => _selectedDuration = v ?? 30),
                  ),

                  const SizedBox(height: 12),

                  // Estado: si es paciente y está creando, dejar 'pendiente'; si paciente editando, permitir sólo cancelar; si doctor, permitir completar/cancelar
                  DropdownButtonFormField<String>(
                    value: estadoSeleccionado,
                    decoration: InputDecoration(
                      labelText: 'Estado de la cita',
                      prefixIcon: const Icon(Icons.flag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: (isDoctor)
                        ? const [
                            DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                            DropdownMenuItem(value: 'completada', child: Text('Completada')),
                            DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                          ]
                        : (isPatient && isEditing)
                            ? const [
                                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                                DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                              ]
                            : const [
                                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                              ],
                    onChanged: (value) {
                      // controlar: paciente no puede marcar completada
                      if (value == 'completada' && !isDoctor) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solo un doctor puede marcar como completada')));
                        return;
                      }
                      setState(() {
                        estadoSeleccionado = value ?? 'pendiente';
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Fecha/hora selector
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
                              // si paciente cancela edición, restauramos
                              citaEnEdicion = null;
                              motivoController.clear();
                              fechaSeleccionada = null;
                              _selectedDoctorId = null;
                              _selectedDoctorName = null;
                              estadoSeleccionado = 'pendiente';
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
    final estado = data['estado'] ?? 'pendiente';
    final usuario = data['nombreUsuario'] ?? data['patientName'] ?? 'Desconocido';
    final patientId = data['patientId'];
    final doctorName = data['doctorName'] ?? '';
    final doctorId = data['doctorId'] ?? '';

    // decidir qué acciones mostrar según rol y propiedad
    final bool isOwner = patientId != null && patientId == _currentUserId;
    final bool isDoctorUser = _currentUserRole == 'doctor';
    final bool canPatientCancel = _currentUserRole == 'paciente' && isOwner;
    final bool canDoctorManage = isDoctorUser && doctorId == _currentUserId;

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
          child: Text('$fechaTexto • Paciente: $usuario • Doctor: $doctorName • Estado: $estado', style: const TextStyle(color: Colors.black54)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Editar: muestra modal de edición si tiene permiso
            if (canPatientCancel || canDoctorManage)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editarCita(doc.id, data),
                tooltip: 'Editar',
              ),
            // Eliminar: solo el dueño (paciente) o admin puede eliminar completamente
            if (isOwner || _currentUserRole == 'administrador')
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
                  const SizedBox(height: 6),
                  Text('Doctor: $doctorName', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text('Estado: $estado', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (canPatientCancel)
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            // paciente cancela la cita
                            await _firestore.collection('citas').doc(doc.id).update({'estado': 'cancelada'});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita cancelada')));
                          },
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade100)),
                        ),
                      if (canDoctorManage) ...[
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _firestore.collection('citas').doc(doc.id).update({'estado': 'completada'});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita marcada como completada')));
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Marcar completada'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _firestore.collection('citas').doc(doc.id).update({'estado': 'cancelada'});
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cita cancelada')));
                          },
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade100)),
                        ),
                      ],
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
          // reset form defaults antes de abrir el modal
          motivoController.clear();
          fechaSeleccionada = null;
          citaEnEdicion = null;
          estadoSeleccionado = 'pendiente';
          _selectedDuration = 30;
          _selectedDoctorId = null;
          _selectedDoctorName = null;
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
