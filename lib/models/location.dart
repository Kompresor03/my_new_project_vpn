class VpnLocation {
  final int id;
  final String country;
  final String city;
  final String flagUrl;
  final String type;
  bool isSelected;

  VpnLocation({
    required this.id,
    required this.country,
    required this.city,
    required this.flagUrl,
    required this.type,
    this.isSelected = false,
  });

  bool get isPremium => type == 'paid';

  factory VpnLocation.fromJson(Map<String, dynamic> json) {
    return VpnLocation(
      id: json['id'],
      country: json['country'],
      city: json['city'],
      flagUrl: json['flag_url'],
      type: json['type'],
      isSelected: false,
    );
  }

  // Добавляем этот метод
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'city': city,
      'flagUrl': flagUrl,
      'type': type,
      'isSelected': isSelected,
    };
  }
}