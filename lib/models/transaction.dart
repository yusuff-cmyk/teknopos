class Transaction {
  final String id;
  final List<String> voucherIds;
  final double totalAmount;
  final DateTime timestamp;
  final String paymentMethod;

  Transaction({
    required this.id,
    required this.voucherIds,
    required this.totalAmount,
    required this.timestamp,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'voucherIds': voucherIds,
    'totalAmount': totalAmount,
    'timestamp': timestamp.toIso8601String(),
    'paymentMethod': paymentMethod,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    voucherIds: List<String>.from(json['voucherIds']),
    totalAmount: json['totalAmount'],
    timestamp: DateTime.parse(json['timestamp']),
    paymentMethod: json['paymentMethod'],
  );
}
