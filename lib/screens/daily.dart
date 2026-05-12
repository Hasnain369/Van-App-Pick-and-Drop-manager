import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/db.dart';
import 'package:flutter_application_1/model/model.dart';
import 'package:intl/intl.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  List<Student> students = [];
  Map<int, DailyRecord> records = {};
  DateTime date = DateTime.now();
  bool loading = true;

  String get dateStr => DateFormat('yyyy-MM-dd').format(date);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final s = await DB.getStudents();
    final r = await DB.getDailyByDate(dateStr);
    final map = {for (final x in r) x.studentId!: x};
    if (mounted)
      setState(() {
        students = s;
        records = map;
        loading = false;
      });
  }

  Future<void> toggle(Student s, bool isPick) async {
    final existing = records[s.id!];
    final updated = DailyRecord(
      studentId: s.id,
      date: dateStr,
      picked: isPick
          ? !(existing?.picked ?? false)
          : (existing?.picked ?? false),
      dropped: !isPick
          ? !(existing?.dropped ?? false)
          : (existing?.dropped ?? false),
    );
    await DB.upsertDaily(updated);
    final fresh = await DB.getDailyByDate(dateStr);
    final map = {for (final x in fresh) x.studentId!: x};
    if (mounted) setState(() => records = map);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      date = picked;
      load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: const Color(0xFF1565C0).withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE, d MMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1565C0),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                ? const Center(
                    child: Text(
                      'No students yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (_, i) {
                      final s = students[i];
                      final r = records[s.id!];
                      final picked = r?.picked ?? false;
                      final dropped = r?.dropped ?? false;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFF1565C0,
                                    ).withOpacity(0.1),
                                    child: Text(
                                      s.name[0],
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '${s.school} • Class ${s.className}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _Btn(
                                      '🚌 Picked',
                                      picked,
                                      const Color(0xFF2E7D32),
                                      () => toggle(s, true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _Btn(
                                      '🏠 Dropped',
                                      dropped,
                                      const Color(0xFF1E88E5),
                                      () => toggle(s, false),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _Btn(this.label, this.active, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            active ? '✓ $label' : label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
