import 'package:rimba/models/transaction.dart';
import 'package:rimba/state/transactions_with_user/transactions_with_user.dart';

List<Transaction> selectUserTransactions(TransactionsWithUserState state) {
  final mergedTransactions = [
    ...state.sendingQueue,
    ...state.newTransactions,
    ...state.transactions
  ];

  return mergedTransactions;
}
