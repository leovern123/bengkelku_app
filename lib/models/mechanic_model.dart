class MechanicModel {
  final String mechanicId;
  final String mechanicName;
  final String? phoneNumber;

  MechanicModel({
    required this.mechanicId,
    required this.mechanicName,
    this.phoneNumber,
  });

  factory MechanicModel.fromJson(Map<String, dynamic> json) => MechanicModel(
        mechanicId: json['mechanic_id']?.toString() ?? '',
        mechanicName: json['mechanic_name']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString(),
      );
}
