import 'package:rimba/models/transaction.dart';
import 'package:rimba/utils/random.dart';

class StatusUpdateRequest {
  final TransactionStatus status;
  final String uuid = generateRandomId();

  StatusUpdateRequest(this.status);

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'uuid': uuid,
      };
}
