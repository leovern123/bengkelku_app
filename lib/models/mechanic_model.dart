class MechanicModel {
  final String mechanicId;
  final String mechanicName;
  final String? nik;
  final String? phoneNumber;
  final String? notes;
  final String? updatedAt;

  MechanicModel({
    required this.mechanicId,
    required this.mechanicName,
    this.nik,
    this.phoneNumber,
    this.notes,
    this.updatedAt,
  });

  factory MechanicModel.fromJson(Map<String, dynamic> json) => MechanicModel(
        mechanicId: json['mechanic_id']?.toString() ?? '',
        mechanicName: json['mechanic_name']?.toString() ?? '',
        nik: json['nik']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        notes: json['notes']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}
