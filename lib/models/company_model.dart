class CompanyModel {
  final String id;
  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String gstin;
  final String drugLicenseNo;
  final String address;
  final String industryType; // Pharma, Retail, Wholesale, FMCG
  final bool isActive;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.gstin,
    required this.drugLicenseNo,
    required this.address,
    required this.industryType,
    this.isActive = true,
    required this.createdAt,
  });
}
