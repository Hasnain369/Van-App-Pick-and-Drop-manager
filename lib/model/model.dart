class Student {
  final int? id;
  final String name, contact, school, className, address;
  final double fee;

  Student({
    this.id,
    required this.name,
    required this.contact,
    required this.school,
    required this.className,
    required this.address,
    required this.fee,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'contact': contact,
    'school': school,
    'class': className,
    'address': address,
    'fee': fee,
  };

  factory Student.fromMap(Map<String, dynamic> m) => Student(
    id: m['id'],
    name: m['name'],
    contact: m['contact'],
    school: m['school'],
    className: m['class'],
    address: m['address'],
    fee: (m['fee'] as num).toDouble(),
  );
}

class DailyRecord {
  final int? id, studentId;
  final String date;
  final bool picked, dropped;

  DailyRecord({
    this.id,
    required this.studentId,
    required this.date,
    this.picked = false,
    this.dropped = false,
  });

  Map<String, dynamic> toMap() => {
    'student_id': studentId,
    'date': date,
    'picked': picked ? 1 : 0,
    'dropped': dropped ? 1 : 0,
  };

  factory DailyRecord.fromMap(Map<String, dynamic> m) => DailyRecord(
    id: m['id'],
    studentId: m['student_id'],
    date: m['date'],
    picked: m['picked'] == 1,
    dropped: m['dropped'] == 1,
  );
}

class Payment {
  final int? id, studentId, month, year;
  final double amount;
  final String status;

  Payment({
    this.id,
    required this.studentId,
    required this.month,
    required this.year,
    required this.amount,
    this.status = 'unpaid',
  });

  bool get isPaid => status == 'paid';

  Map<String, dynamic> toMap() => {
    'student_id': studentId,
    'month': month,
    'year': year,
    'amount': amount,
    'status': status,
  };

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: m['id'],
    studentId: m['student_id'],
    month: m['month'],
    year: m['year'],
    amount: (m['amount'] as num).toDouble(),
    status: m['status'],
  );
}
