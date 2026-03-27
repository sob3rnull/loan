class Borrower {
  const Borrower({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final String createdAt;
  final String updatedAt;

  Borrower copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return Borrower(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Map<String, Object?> toJson() => toMap();

  factory Borrower.fromMap(Map<String, Object?> map) {
    return Borrower(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  factory Borrower.fromJson(Map<String, dynamic> json) {
    return Borrower(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

