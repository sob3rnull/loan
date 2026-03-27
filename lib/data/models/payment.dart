class Payment {
  const Payment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paymentDate,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String loanId;
  final double amount;
  final String paymentDate;
  final String? note;
  final String createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'loan_id': loanId,
      'amount': amount,
      'payment_date': paymentDate,
      'note': note,
      'created_at': createdAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as String,
      loanId: map['loan_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: map['payment_date'] as String,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['payment_date'] as String,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

