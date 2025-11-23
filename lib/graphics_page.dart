import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';


class GraphicsPage extends StatefulWidget {
  const GraphicsPage({super.key});

  @override
  State<GraphicsPage> createState() => _GraphicsPageState();
}

class _GraphicsPageState extends State<GraphicsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estadísticas"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Citas creadas por mes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // === GRAFICA #1 ===
            SizedBox(height: 250, child: _monthlyAppointmentsChart()),

            const SizedBox(height: 40),
            const Text("Citas completadas vs canceladas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // === GRAFICA #2 ===
            SizedBox(height: 250, child: _statusPieChart()),
          ],
        ),
      ),
    );
  }

  /// -----------------------------
  /// GRAFICA 1 – BARRAS MENSUALES
  /// -----------------------------
  Widget _monthlyAppointmentsChart() {
  // Usamos FutureBuilder para obtener los datos de Firestore una vez
  return FutureBuilder<QuerySnapshot>(
    future: FirebaseFirestore.instance.collection('citas').get(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      // Contador de citas por mes
      final Map<int, int> citasPorMes = {};

      for (var doc in snapshot.data!.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['fechaHora'] as Timestamp).toDate();
        final month = date.month;

        // Incrementa el contador de citas para cada mes
        citasPorMes[month] = (citasPorMes[month] ?? 0) + 1;
      }

      // Generamos las barras para la gráfica
      final barGroups = citasPorMes.entries
          .map(
            (e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble(),
                  width: 16,
                  color: Colors.teal, // Color uniforme para todas las barras
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          )
          .toList();

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (citasPorMes.values.isNotEmpty
                  ? citasPorMes.values.reduce((a, b) => a > b ? a : b)
                  : 1)
              .toDouble() + 2, // Agregamos un margen superior
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Convertimos el número del mes en nombre de mes
                  const meses = [
                    '',
                    'Ene',
                    'Feb',
                    'Mar',
                    'Abr',
                    'May',
                    'Jun',
                    'Jul',
                    'Ago',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dic'
                  ];
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      meses[value.toInt()],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
          gridData: FlGridData(show: true),
        ),
      );
    },
  );
}


  /// -----------------------------
  /// GRAFICA 2 – PIE (ESTADO)
  /// -----------------------------
  Widget _statusPieChart() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('citas').snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      int completadas = 0;
      int canceladas = 0;

      for (var doc in snapshot.data!.docs) {
        final estado = doc['estado'];
        if (estado == 'completada') completadas++;
        if (estado == 'cancelada') canceladas++;
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Limitamos la altura del PieChart para evitar overflow
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: completadas.toDouble(),
                    title: "Completadas",
                    radius: 50,
                    color: Colors.teal,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: canceladas.toDouble(),
                    title: "Canceladas",
                    radius: 50,
                    color: Colors.redAccent,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                "Completadas: $completadas",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
              Text(
                "Canceladas: $canceladas",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent),
              ),
            ],
          ),
        ],
      );
    },
  );
}

}