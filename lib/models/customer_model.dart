class PrescriptionRx {
  final String id;
  final String doctorName;
  final String doctorMci;
  final DateTime uploadDate;
  final String imageUrl;
  final List<String> prescribedMedications;

  PrescriptionRx({
    required this.id,
    required this.doctorName,
    required this.doctorMci,
    required this.uploadDate,
    required this.imageUrl,
    required this.prescribedMedications,
  });
}

class ChronicRefillItem {
  final String medicineName;
  final int refillIntervalDays;
  final DateTime lastPurchasedDate;
  final DateTime nextRefillDueDate;

  ChronicRefillItem({
    required this.medicineName,
    required this.refillIntervalDays,
    required this.lastPurchasedDate,
    required this.nextRefillDueDate,
  });

  bool get isDueSoon => nextRefillDueDate.difference(DateTime.now()).inDays <= 5;
}

class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final List<PrescriptionRx> prescriptions;
  final List<ChronicRefillItem> chronicRefills;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.prescriptions,
    required this.chronicRefills,
  });
}
