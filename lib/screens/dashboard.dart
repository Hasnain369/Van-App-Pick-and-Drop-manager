import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/db.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int total = 0, picked = 0, dropped = 0, unpaid = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final now = DateTime.now();
    final students = await DB.getStudents();
    await DB.ensurePayments(students, now.month, now.year);
    setState(() {
      total = students.length;
      loading = false;
    });
    final p = await DB.countPicked(today);
    final d = await DB.countDropped(today);
    final u = await DB.countUnpaid(now.month, now.year);
    if (mounted)
      setState(() {
        picked = p;
        dropped = d;
        unpaid = u;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚐 Van Manager'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: load)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                          ).format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Today\'s Summary',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _Card(
                        'Total',
                        '$total',
                        Icons.groups,
                        const Color(0xFF1565C0),
                      ),
                      _Card(
                        'Picked',
                        '$picked',
                        Icons.directions_bus,
                        const Color(0xFF2E7D32),
                      ),
                      _Card(
                        'Dropped',
                        '$dropped',
                        Icons.home,
                        const Color(0xFF1E88E5),
                      ),
                      _Card(
                        'Unpaid',
                        '$unpaid',
                        Icons.payment,
                        unpaid > 0
                            ? const Color(0xFFC62828)
                            : const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Card(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
