import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<int> _countCitas() async {
    final snap = await FirebaseFirestore.instance.collection('citas').get();
    return snap.size;
  }

  Future<int> _countPendientes() async {
    final snap = await FirebaseFirestore.instance
        .collection('citas')
        .where('status', isEqualTo: 'pendiente')
        .get();
    return snap.size;
  }

  Future<int> _countPacientes() async {
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('role', isEqualTo: 'paciente')
        .get();
    return snap.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard del Doctor'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: Future.wait([
            _countCitas(),
            _countPendientes(),
            _countPacientes(),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final totalCitas = snapshot.data![0];
            final pendientes = snapshot.data![1];
            final pacientes = snapshot.data![2];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen general',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _statCard(
                  title: 'Total de Citas',
                  value: '$totalCitas',
                  icon: Icons.calendar_month,
                  color: Colors.blueAccent,
                ),

                const SizedBox(height: 16),

                _statCard(
                  title: 'Citas Pendientes',
                  value: '$pendientes',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),

                const SizedBox(height: 16),

                _statCard(
                  title: 'Pacientes Registrados',
                  value: '$pacientes',
                  icon: Icons.people,
                  color: Colors.green,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.18),
              radius: 30,
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
