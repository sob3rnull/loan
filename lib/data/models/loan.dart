class Loan {
  const Loan({
    required this.id,
    required this.borrowerId,
    required this.principal,
    required this.interestValue,
    required this.interestType,
    required this.totalRepayable,
    required this.amountPaid,
    required this.remainingAmount,
    this.startDate,
    this.dueDate,
    required this.status,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String borrowerId;
  final double principal;
  final double interestValue;
  final String interestType;
  final double totalRepayable;
  final double amountPaid;
  final double remainingAmount;
  final String? startDate;
  final String? dueDate;
  final String status;
  final String? note;
  final String createdAt;
  final String updatedAt;

  Loan copyWith({
    String? id,
    String? borrowerId,
    double? principal,
    double? interestValue,
    String? interestType,
    double? totalRepayable,
    double? amountPaid,
    double? remainingAmount,
    String? startDate,
    String? dueDate,
    String? status,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return Loan(
      id: id ?? this.id,
      borrowerId: borrowerId ?? this.borrowerId,
      principal: principal ?? this.principal,
      interestValue: interestValue ?? this.interestValue,
      interestType: interestType ?? this.interestType,
      totalRepayable: totalRepayable ?? this.totalRepayable,
      amountPaid: amountPaid ?? this.amountPaid,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'borrower_id': borrowerId,
      'principal': principal,
      'interest_value': interestValue,
      'interest_type': interestType,
      'total_repayable': totalRepayable,
      'amount_paid': amountPaid,
      'remaining_amount': remainingAmount,
      'start_date': startDate,
      'due_date': dueDate,
      'status': status,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory Loan.fromMap(Map<String, Object?> map) {
    return Loan(
      id: map['id'] as String,
      borrowerId: map['borrower_id'] as String,
      principal: (map['principal'] as num).toDouble(),
      interestValue: (map['interest_value'] as num).toDouble(),
      interestType: map['interest_type'] as String,
      totalRepayable: (map['total_repayable'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      remainingAmount: (map['remaining_amount'] as num).toDouble(),
      startDate: map['start_date'] as String?,
      dueDate: map['due_date'] as String?,
      status: map['status'] as String,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      borrowerId: json['borrower_id'] as String,
      principal: (json['principal'] as num).toDouble(),
      interestValue: (json['interest_value'] as num).toDouble(),
      interestType: json['interest_type'] as String,
      totalRepayable: (json['total_repayable'] as num).toDouble(),
      amountPaid: (json['amount_paid'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      startDate: json['start_date'] as String?,
      dueDate: json['due_date'] as String?,
      status: json['status'] as String,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

