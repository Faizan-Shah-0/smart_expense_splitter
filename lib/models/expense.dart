class Expense {
  final String expenseId;
  final String tripId;
  final double amount;
  final String currency;
  final String paidByUserId;
  final List<String> participantUserIds;
  final String? notes;
  final DateTime createdAt;

  const Expense({
    required this.expenseId,
    required this.tripId,
    required this.amount,
    required this.currency,
    required this.paidByUserId,
    required this.participantUserIds,
    required this.createdAt,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'expenseId': expenseId,
        'tripId': tripId,
        'amount': amount,
        'currency': currency,
        'paidByUserId': paidByUserId,
        'participantUserIds': participantUserIds,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        expenseId: json['expenseId'] as String,
        tripId: json['tripId'] as String,
        amount: (json['amount'] as num).toDouble(),
        currency: json['currency'] as String,
        paidByUserId: json['paidByUserId'] as String,
        participantUserIds:
            (json['participantUserIds'] as List).map((e) => e as String).toList(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}



