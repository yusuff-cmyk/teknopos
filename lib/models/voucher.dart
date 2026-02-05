class Voucher {
  final String id;
  final String code;
  final String category;
  final double price;
  final bool isSold;
  final DateTime? soldAt;

  Voucher({
    required this.id,
    required this.code,
    required this.category,
    required this.price,
    required this.isSold,
    this.soldAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'category': category,
    'price': price,
    'isSold': isSold,
    'soldAt': soldAt?.toIso8601String(),
  };

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    id: json['id'],
    code: json['code'],
    category: json['category'],
    price: json['price'],
    isSold: json['isSold'],
    soldAt: json['soldAt'] != null ? DateTime.parse(json['soldAt']) : null,
  );
}

class Packet {
  final String id;
  final String name;
  final double price;

  Packet({required this.id, required this.name, required this.price});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};

  factory Packet.fromJson(Map<String, dynamic> json) => Packet(
    id: json['id'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
  );
}
