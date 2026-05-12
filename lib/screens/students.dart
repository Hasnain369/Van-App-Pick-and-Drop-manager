import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/db/db.dart';
import 'package:flutter_application_1/model/model.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<Student> students = [];
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
    search.addListener(() => load(search.text));
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load([String q = '']) async {
    final list = await DB.getStudents(q);
    if (mounted) setState(() => students = list);
  }

  void openForm([Student? s]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StudentForm(student: s)),
    );
    if (saved == true) load(search.text);
  }

  void confirmDelete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Student?'),
        content: Text('Remove ${s.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DB.deleteStudent(s.id!);
      load(search.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add'),
        backgroundColor: const Color(0xFFFF8F00),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? const Center(
                    child: Text(
                      'No students. Tap + to add.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: students.length,
                    itemBuilder: (_, i) {
                      final s = students[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF1565C0,
                            ).withOpacity(0.12),
                            child: Text(
                              s.name[0],
                              style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${s.school} • Class ${s.className}\n📞 ${s.contact} • Rs. ${s.fee.toStringAsFixed(0)}/mo',
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                            onSelected: (v) {
                              if (v == 'edit')
                                openForm(s);
                              else
                                confirmDelete(s);
                            },
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

// ─── Student Form ─────────────────────────────────────────────────────────────

class StudentForm extends StatefulWidget {
  final Student? student;
  const StudentForm({super.key, this.student});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.student?.name);
  late final contact = TextEditingController(text: widget.student?.contact);
  late final school = TextEditingController(text: widget.student?.school);
  late final cls = TextEditingController(text: widget.student?.className);
  late final address = TextEditingController(text: widget.student?.address);
  late final fee = TextEditingController(
    text: widget.student != null ? widget.student!.fee.toStringAsFixed(0) : '',
  );

  @override
  void dispose() {
    for (final c in [name, contact, school, cls, address, fee]) c.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!_form.currentState!.validate()) return;
    final s = Student(
      id: widget.student?.id,
      name: name.text.trim(),
      contact: contact.text.trim(),
      school: school.text.trim(),
      className: cls.text.trim(),
      address: address.text.trim(),
      fee: double.tryParse(fee.text.trim()) ?? 0,
    );
    if (widget.student == null)
      await DB.addStudent(s);
    else
      await DB.updateStudent(s);
    if (mounted) Navigator.pop(context, true);
  }

  Widget field(
    TextEditingController c,
    String label, {
    TextInputType? type,
    List<TextInputFormatter>? fmt,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        inputFormatters: fmt,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => v!.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student == null ? 'Add Student' : 'Edit Student'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            field(name, 'Student Name', required: true),
            field(contact, 'Guardian Contact', type: TextInputType.phone),
            field(school, 'School Name'),
            field(cls, 'Class'),
            field(address, 'Address'),
            field(
              fee,
              'Monthly Fee (Rs.)',
              type: const TextInputType.numberWithOptions(decimal: true),
              fmt: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: save, child: const Text('Save Student')),
          ],
        ),
      ),
    );
  }
}
