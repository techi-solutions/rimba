// Simple lending group model for local testing
// This is separate from the main app's data models

enum SimpleGroupStatus {
  forming,
  active,
  completed,
}

class SimpleMember {
  final String name;
  final String username;
  final String? imageUrl;
  final double monthlyAmount;
  final bool isAdmin;

  SimpleMember({
    required this.name,
    required this.username,
    this.imageUrl,
    required this.monthlyAmount,
    this.isAdmin = false,
  });
}

class SimpleLendingGroup {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final SimpleGroupStatus status;
  final double baseAmount;
  final int totalMembers;
  final int currentMembers;
  final int totalRounds;
  final int currentRound;
  final List<SimpleMember> members;

  SimpleLendingGroup({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.baseAmount,
    required this.totalMembers,
    required this.currentMembers,
    required this.totalRounds,
    required this.currentRound,
    required this.members,
  });

  // Helper getters
  bool get isActive => status == SimpleGroupStatus.active;
  double get totalPoolAmount => baseAmount * totalMembers;
  double get progressPercentage => totalRounds > 0 ? (currentRound / totalRounds) * 100 : 0;
  
  String get statusText {
    switch (status) {
      case SimpleGroupStatus.forming:
        return 'Forming';
      case SimpleGroupStatus.active:
        return 'Active';
      case SimpleGroupStatus.completed:
        return 'Completed';
    }
  }
}

