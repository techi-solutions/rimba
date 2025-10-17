
class PaymentCalculator {
  /// Calculate the monthly contribution for a member based on their position
  ///
  /// [totalPoolAmount] - The total amount to be distributed each month (e.g., $2000)
  /// [memberCount] - Total number of members in the group
  /// [position] - Member's position (0 = first to receive, memberCount-1 = last)
  /// [differentialRate] - The percentage differential between adjacent positions (default: 0.0375 for 3.75%)
  ///
  /// Returns the monthly contribution amount for this member
  static double calculateMonthlyContribution({
    required double totalPoolAmount,
    required int memberCount,
    required int position,
    double differentialRate = 0.0375,
  }) {
    if (memberCount <= 0) return 0.0;
    if (position < 0 || position >= memberCount) return 0.0;
    
    // Calculate base amount (equal split)
    final baseAmount = totalPoolAmount / memberCount;
    
    // Calculate the middle position
    final middlePosition = (memberCount - 1) / 2.0;
    
    // Calculate offset from middle
    final offset = middlePosition - position;
    
    // Calculate monthly payment
    // Earlier positions (position 0) have positive offset and pay more
    // Later positions have negative offset and pay less
    final monthlyPayment = baseAmount * (1 + (offset * differentialRate));
    
    return monthlyPayment;
  }
  
  /// Calculate monthly contributions for all members
  ///
  /// Returns a list of monthly contributions indexed by position
  static List<double> calculateAllContributions({
    required double totalPoolAmount,
    required int memberCount,
    double differentialRate = 0.0375,
  }) {
    final contributions = <double>[];
    
    for (int position = 0; position < memberCount; position++) {
      final contribution = calculateMonthlyContribution(
        totalPoolAmount: totalPoolAmount,
        memberCount: memberCount,
        position: position,
        differentialRate: differentialRate,
      );
      contributions.add(contribution);
    }
    
    return contributions;
  }
  
  /// Verify that the sum of all contributions equals the total pool amount
  ///
  /// Returns true if the contributions sum correctly (within a small margin of error)
  static bool verifyContributions({
    required double totalPoolAmount,
    required int memberCount,
    double differentialRate = 0.0375,
    double tolerance = 0.01,
  }) {
    final contributions = calculateAllContributions(
      totalPoolAmount: totalPoolAmount,
      memberCount: memberCount,
      differentialRate: differentialRate,
    );
    
    final sum = contributions.reduce((a, b) => a + b);
    final difference = (sum - totalPoolAmount).abs();
    
    return difference <= tolerance;
  }
  
  /// Get the position of a member who will receive the pool in a given month
  ///
  /// [monthNumber] - 1-based month number (1 = first month, 2 = second month, etc.)
  /// [memberCount] - Total number of members
  ///
  /// Returns the position of the member receiving the pool this month
  static int getRecipientPosition(int monthNumber, int memberCount) {
    if (monthNumber < 1 || memberCount <= 0) return 0;
    return (monthNumber - 1) % memberCount;
  }
  
  /// Calculate the total amount a member will pay over the full cycle
  ///
  /// Each member pays their monthly contribution for N months
  /// where N is the number of members.
  static double calculateTotalContribution({
    required double totalPoolAmount,
    required int memberCount,
    required int position,
    double differentialRate = 0.0375,
  }) {
    final monthlyContribution = calculateMonthlyContribution(
      totalPoolAmount: totalPoolAmount,
      memberCount: memberCount,
      position: position,
      differentialRate: differentialRate,
    );
    
    return monthlyContribution * memberCount;
  }
  
  /// Calculate the net benefit (or cost) for a member
  ///
  /// This shows how much more (or less) a member pays compared to what they receive.
  /// - Negative value: member pays less than they receive (benefit)
  /// - Positive value: member pays more than they receive (cost)
  /// - Zero: member pays exactly what they receive
  static double calculateNetCost({
    required double totalPoolAmount,
    required int memberCount,
    required int position,
    double differentialRate = 0.0375,
  }) {
    final totalPaid = calculateTotalContribution(
      totalPoolAmount: totalPoolAmount,
      memberCount: memberCount,
      position: position,
      differentialRate: differentialRate,
    );
    
    return totalPaid - totalPoolAmount;
  }
  
  /// Get a formatted breakdown of all member contributions
  ///
  /// Useful for displaying in UI or debugging
  static Map<int, Map<String, dynamic>> getContributionBreakdown({
    required double totalPoolAmount,
    required int memberCount,
    double differentialRate = 0.0375,
  }) {
    final breakdown = <int, Map<String, dynamic>>{};
    
    for (int position = 0; position < memberCount; position++) {
      final monthlyContribution = calculateMonthlyContribution(
        totalPoolAmount: totalPoolAmount,
        memberCount: memberCount,
        position: position,
        differentialRate: differentialRate,
      );
      
      final totalContribution = calculateTotalContribution(
        totalPoolAmount: totalPoolAmount,
        memberCount: memberCount,
        position: position,
        differentialRate: differentialRate,
      );
      
      final netCost = calculateNetCost(
        totalPoolAmount: totalPoolAmount,
        memberCount: memberCount,
        position: position,
        differentialRate: differentialRate,
      );
      
      breakdown[position] = {
        'position': position,
        'monthNumber': position + 1,
        'monthlyContribution': monthlyContribution,
        'totalContribution': totalContribution,
        'amountReceived': totalPoolAmount,
        'netCost': netCost,
      };
    }
    
    return breakdown;
  }
}

