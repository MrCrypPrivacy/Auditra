class WalletProfile {
  final String name;
  final String address;

  const WalletProfile({required this.name, required this.address});

  factory WalletProfile.fromJson(Map<String, dynamic> json) {
    return WalletProfile(
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'address': address};
}
