class CustomRate {
  final String id;
  final String name;
  final String value;
  final String icon;

  const CustomRate({
    required this.id,
    required this.name,
    required this.value,
    required this.icon,
  });

  CustomRate copyWith({String? name, String? value, String? icon}) {
    return CustomRate(
      id: id,
      name: name ?? this.name,
      value: value ?? this.value,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'value': value,
        'icon': icon,
      };

  factory CustomRate.fromJson(Map<String, dynamic> json) => CustomRate(
        id: json['id'] as String,
        name: json['name'] as String,
        value: json['value'] as String,
        icon: json['icon'] as String,
      );
}
