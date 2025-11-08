import '../models/expense.dart';

class BalanceService {
  /// Returns net balances per user for a trip: positive means others owe them; negative means they owe.
  Map<String, double> computeNetBalances(List<Expense> expenses) {
    final net = <String, double>{};
    for (final e in expenses) {
      final participants = e.participantUserIds.toSet().toList();
      if (participants.isEmpty) continue;
      final share = e.amount / participants.length;

      // Payer pays amount
      net[e.paidByUserId] = (net[e.paidByUserId] ?? 0) + e.amount;
      // Each participant owes share
      for (final uid in participants) {
        net[uid] = (net[uid] ?? 0) - share;
      }
    }
    // Round to 2 decimals for display
    return net.map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2))));
  }

  /// Greedy settlement pairs approximate minimal transfers.
  List<Settlement> computeSettlements(Map<String, double> net) {
    final debtors = <_Node>[];
    final creditors = <_Node>[];
    net.forEach((uid, amount) {
      if (amount < -0.009) debtors.add(_Node(uid, -amount));
      if (amount > 0.009) creditors.add(_Node(uid, amount));
    });
    debtors.sort((a, b) => b.amount.compareTo(a.amount));
    creditors.sort((a, b) => b.amount.compareTo(a.amount));

    final settlements = <Settlement>[];
    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      final d = debtors[i];
      final c = creditors[j];
      final pay = d.amount < c.amount ? d.amount : c.amount;
      settlements.add(Settlement(fromUserId: d.userId, toUserId: c.userId, amount: _round2(pay)));
      d.amount -= pay;
      c.amount -= pay;
      if (d.amount <= 0.009) i++;
      if (c.amount <= 0.009) j++;
    }
    return settlements;
  }

  double _round2(double v) => double.parse(v.toStringAsFixed(2));
}

class Settlement {
  final String fromUserId;
  final String toUserId;
  final double amount;
  Settlement({required this.fromUserId, required this.toUserId, required this.amount});
}

class _Node {
  final String userId;
  double amount;
  _Node(this.userId, this.amount);
}




