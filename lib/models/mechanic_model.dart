class MechanicModel {
  final String mechanicId;
  final String mechanicName;
  final String? nik;
  final String? phoneNumber;
  final String? address;
  final String? notes;
  final String? photo;
  final String? photoUrl;
  final String? updatedAt;

  MechanicModel({
    required this.mechanicId,
    required this.mechanicName,
    this.nik,
    this.phoneNumber,
    this.address,
    this.notes,
    this.photo,
    this.photoUrl,
    this.updatedAt,
  });

  factory MechanicModel.fromJson(Map<String, dynamic> json) => MechanicModel(
        mechanicId: json['mechanic_id']?.toString() ?? '',
        mechanicName: json['mechanic_name']?.toString() ?? '',
        nik: json['nik']?.toString(),
        phoneNumber: json['phone_number']?.toString(),
        address: json['address']?.toString(),
        notes: json['notes']?.toString(),
        photo: json['photo']?.toString(),
        photoUrl: json['photo_url']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}
