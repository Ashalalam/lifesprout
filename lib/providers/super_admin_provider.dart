import 'package:flutter/foundation.dart';
import '../models/company_model.dart';

class SuperAdminProvider extends ChangeNotifier {
  final List<CompanyModel> _tenants = [];
  final double _monthlySaasRevenue = 48500.0;
  int _activeStoresCount = 142;

  List<CompanyModel> get tenants => List.unmodifiable(_tenants);
  double get monthlySaasRevenue => _monthlySaasRevenue;
  int get activeStoresCount => _activeStoresCount;

  SuperAdminProvider() {
    _seedSampleTenants();
  }

  void addCompanyTenant(CompanyModel company) {
    _tenants.add(company);
    _activeStoresCount++;
    notifyListeners();
  }

  void toggleTenantStatus(String companyId) {
    final index = _tenants.indexWhere((c) => c.id == companyId);
    if (index >= 0) {
      final old = _tenants[index];
      _tenants[index] = CompanyModel(
        id: old.id,
        businessName: old.businessName,
        ownerName: old.ownerName,
        email: old.email,
        phone: old.phone,
        gstin: old.gstin,
        drugLicenseNo: old.drugLicenseNo,
        address: old.address,
        industryType: old.industryType,
        isActive: !old.isActive,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  void _seedSampleTenants() {
    _tenants.addAll([
      CompanyModel(
        id: 'comp_1',
        businessName: 'LIFESPROUT Care Pharmacy - Main Branch',
        ownerName: 'Dr. Sarah Connor',
        email: 'info@lifesproutcare.com',
        phone: '+44 7747 571513',
        gstin: '07AAAAA1234A1Z5',
        drugLicenseNo: 'DL-2024-98123',
        address: 'Healthcare Hub, Central Square',
        industryType: 'Pharma',
        isActive: true,
        createdAt: DateTime(2024, 1, 10),
      ),
      CompanyModel(
        id: 'comp_2',
        businessName: 'Apex Healthcare Distribution',
        ownerName: 'Robert Vance',
        email: 'vance@apexpharma.com',
        phone: '+44 7700 900123',
        gstin: '27BBBBB5678B1Z2',
        drugLicenseNo: 'DL-2024-44109',
        address: 'Industrial Park Zone B',
        industryType: 'Wholesale',
        isActive: true,
        createdAt: DateTime(2024, 3, 15),
      ),
      CompanyModel(
        id: 'comp_3',
        businessName: 'Sprout Retail Supermarket',
        ownerName: 'Elena Rostova',
        email: 'elena@sproutretail.com',
        phone: '+44 7700 888222',
        gstin: '09CCCCC9012C1Z8',
        drugLicenseNo: 'N/A',
        address: 'Metro Mall Level 1',
        industryType: 'Retail',
        isActive: true,
        createdAt: DateTime(2024, 5, 20),
      ),
    ]);
  }
}
