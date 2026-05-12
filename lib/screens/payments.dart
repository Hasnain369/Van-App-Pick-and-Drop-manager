import 'package:flutter/material.dart';
import 'package:flutter_application_1/db/db.dart';
import 'package:flutter_application_1/model/model.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Student> students = [];
  Map<int, Payment> payments = {};
  int month = DateTime.now().month;
  int year = DateTime.now().year;
  bool loading = true;
  bool unpaidOnly = false;

  static const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final s = await DB.getStudents();
    await DB.ensurePayments(s, month, year);
    final p = await DB.getPayments(month, year);
    final map = {for (final x in p) x.studentId!: x};
    if (mounted)
      setState(() {
        students = s;
        payments = map;
        loading = false;
      });
  }

  Future<void> toggle(Student s) async {
    final p = payments[s.id!];
    final updated = Payment(
      studentId: s.id,
      month: month,
      year: year,
      amount: p?.amount ?? s.fee,
      status: p?.isPaid == true ? 'unpaid' : 'paid',
    );
    await DB.upsertPayment(updated);
    final fresh = await DB.getPayments(month, year);
    if (mounted)
      setState(() => payments = {for (final x in fresh) x.studentId!: x});
  }

  void prevMonth() {
    month == 1 ? (month = 12, year--) : month--;
    load();
  }

  void nextMonth() {
    final now = DateTime.now();
    if (year == now.year && month == now.month) return;
    month == 12 ? (month = 1, year++) : month++;
    load();
  }

  int get paidCount => payments.values.where((p) => p.isPaid).length;
  double get collected =>
      payments.values.where((p) => p.isPaid).fold(0, (s, p) => s + p.amount);
  List<Student> get displayed => unpaidOnly
      ? students.where((s) => payments[s.id!]?.isPaid != true).toList()
      : students;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = month == now.month && year == now.year;

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: Column(
        children: [
          // Month nav
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: prevMonth,
                ),
                Text(
                  '${months[month - 1]} $year',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isCurrent ? null : nextMonth,
                ),
              ],
            ),
          ),
          // Summary
          if (!loading)
            Container(
              color: const Color(0xFF1565C0).withOpacity(0.06),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _chip('Paid', '$paidCount', const Color(0xFF2E7D32)),
                  _chip(
                    'Unpaid',
                    '${students.length - paidCount}',
                    const Color(0xFFC62828),
                  ),
                  _chip(
                    'Collected',
                    'Rs. ${collected.toStringAsFixed(0)}',
                    const Color(0xFF1565C0),
                  ),
                ],
              ),
            ),
          // Filter
          SwitchListTile(
            title: const Text(
              'Show unpaid only',
              style: TextStyle(fontSize: 14),
            ),
            value: unpaidOnly,
            onChanged: (v) => setState(() => unpaidOnly = v),
            activeColor: const Color(0xFF1565C0),
            dense: true,
          ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : displayed.isEmpty
                ? Center(
                    child: Text(
                      unpaidOnly ? '🎉 All paid!' : 'No students.',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayed.length,
                    itemBuilder: (_, i) {
                      final s = displayed[i];
                      final p = payments[s.id!];
                      final paid = p?.isPaid ?? false;

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            paid
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: paid ? const Color(0xFF2E7D32) : Colors.grey,
                            size: 28,
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Rs. ${(p?.amount ?? s.fee).toStringAsFixed(0)} • ${s.school}',
                          ),
                          trailing: GestureDetector(
                            onTap: () => toggle(s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: paid
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: paid
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: Text(
                                paid ? 'Paid ✓' : 'Mark Paid',
                                style: TextStyle(
                                  color: paid
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
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

  Widget _chip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
