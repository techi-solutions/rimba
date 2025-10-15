import 'package:pay_app/models/group.dart';

extension GroupPermissions on Group {
  /// Check if the given user address is the creator of this group
  ///
  /// Returns true if:
  /// - The user's address matches the createdBy field (case-insensitive)
  /// - createdBy is null (for backwards compatibility with existing groups)
  ///
  /// Returns false if:
  /// - userAddress is null
  /// - userAddress doesn't match createdBy
  bool isCreator(String? userAddress) {
    if (createdBy == null) return true;

    if (userAddress == null) return false;

    return createdBy!.toLowerCase() == userAddress.toLowerCase();
  }
}
