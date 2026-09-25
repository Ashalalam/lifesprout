import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerModel _currentCustomer = CustomerModel(
    id: 'cust_77',
    name: 'John Doe',
    phone: '+44 7747 571513',
    email: 'info@lifesproutcare.com',
    address: '221B Baker Street, London / Healthcare Sector 4',
    prescriptions: [
      PrescriptionRx(
        id: 'rx_101',
        doctorName: 'Dr. Arthur Conan',
        doctorMci: 'MCI-99410',
        uploadDate: DateTime.now().subtract(const Duration(days: 15)),
        imageUrl: 'assets/images/lifesprout_logo.jpg',
        prescribedMedications: ['Metformin 500mg SR', 'Amoxicillin 500mg'],
      ),
    ],
    chronicRefills: [
      ChronicRefillItem(
        medicineName: 'Metformin 500mg SR',
        refillIntervalDays: 30,
        lastPurchasedDate: DateTime.now().subtract(const Duration(days: 25)),
        nextRefillDueDate: DateTime.now().add(const Duration(days: 5)),
      ),
      ChronicRefillItem(
        medicineName: 'Atorvastatin 10mg',
        refillIntervalDays: 30,
        lastPurchasedDate: DateTime.now().subtract(const Duration(days: 28)),
        nextRefillDueDate: DateTime.now().add(const Duration(days: 2)),
      ),
    ],
  );

  final List<InvoiceModel> _customerInvoices = [];

  CustomerModel get currentCustomer => _currentCustomer;
  List<InvoiceModel> get customerInvoices => List.unmodifiable(_customerInvoices);

  void addCustomerInvoice(InvoiceModel invoice) {
    _customerInvoices.add(invoice);
    notifyListeners();
  }

  void requestChronicRefill(ChronicRefillItem item) {
    // Triggers WhatsApp message or notification
    notifyListeners();
  }
}
