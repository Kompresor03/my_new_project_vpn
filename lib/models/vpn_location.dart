class VpnLocation {
  final int id;
  final String country;
  final String city;
  final String type;
  final String flag;
  final String? config;  // Добавляем поле для конфига
  bool isSelected;
  bool isActive;  // Добавляем статус активности

  VpnLocation({
    required this.id,
    required this.country,
    required this.city,
    required this.type,
    required this.flag,
    this.config,
    this.isSelected = false,
    this.isActive = false,
  });

  factory VpnLocation.fromJson(Map<String, dynamic> json) {
    return VpnLocation(
      id: json['id'],
      country: json['country'],
      city: json['city'],
      type: json['type'],
      flag: json['flag_url'] ?? json['flag'] ?? '',
      config: json['config'],
    );
  }
}