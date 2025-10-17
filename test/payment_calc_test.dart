import 'package:flutter_test/flutter_test.dart';
import 'package:pay_app/utils/payment_calc.dart';

void main() {
  group('PaymentCalculator', () {
    test(
        'calculates monthly contributions correctly for 5 members with \$2000 pool',
        () {
      const totalPool = 2000.0;
      const memberCount = 5;

      final contributions = PaymentCalculator.calculateAllContributions(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
      );

      // Verify we have 5 contributions
      expect(contributions.length, equals(5));

      // Verify position 0 (first to receive) pays the most
      expect(contributions[0], greaterThan(contributions[1]));
      expect(contributions[1], greaterThan(contributions[2]));
      expect(contributions[2], greaterThan(contributions[3]));
      expect(contributions[3], greaterThan(contributions[4]));

      // Print contributions for visibility
      for (int i = 0; i < contributions.length; i++) {
        print(
            'Position $i (Month ${i + 1}): \$${contributions[i].toStringAsFixed(2)}');
      }

      // Verify the middle position pays the base amount
      final baseAmount = totalPool / memberCount;
      expect(contributions[2], closeTo(baseAmount, 0.01));

      // Verify total equals pool amount
      final total = contributions.reduce((a, b) => a + b);
      expect(total, closeTo(totalPool, 0.01));
    });

    test('calculates correct monthly contribution for specific member', () {
      const totalPool = 2000.0;
      const memberCount = 5;

      // Position 0 (first to receive, pays most)
      final position0Payment = PaymentCalculator.calculateMonthlyContribution(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
        position: 0,
      );

      // Position 2 (middle, pays base amount)
      final position2Payment = PaymentCalculator.calculateMonthlyContribution(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
        position: 2,
      );

      // Position 4 (last to receive, pays least)
      final position4Payment = PaymentCalculator.calculateMonthlyContribution(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
        position: 4,
      );

      expect(position0Payment, greaterThan(position2Payment));
      expect(position2Payment, greaterThan(position4Payment));
      expect(position2Payment, closeTo(400.0, 0.01));
    });

    test('verifies contributions sum correctly', () {
      const totalPool = 2000.0;
      const memberCount = 5;

      final isValid = PaymentCalculator.verifyContributions(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
      );

      expect(isValid, isTrue);
    });

    test('calculates total contribution over full cycle', () {
      const totalPool = 2000.0;
      const memberCount = 5;

      // Each member pays their monthly amount for N months
      final totalContribution = PaymentCalculator.calculateTotalContribution(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
        position: 0,
      );

      // Total contribution should be monthly payment × number of months
      final monthlyPayment = PaymentCalculator.calculateMonthlyContribution(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
        position: 0,
      );

      expect(totalContribution, closeTo(monthlyPayment * memberCount, 0.01));
    });

    test('calculates net cost correctly', () {
      const totalPool = 2000.0;
      const memberCount = 5;

      // Position 0 (pays more, so positive net cost)
      final netCost0 = PaymentCalculator.calculateNetCost(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
        position: 0,
      );

      // Position 4 (pays less, so negative net cost = benefit)
      final netCost4 = PaymentCalculator.calculateNetCost(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
        position: 4,
      );

      // Position 0 should have a cost (positive)
      expect(netCost0, greaterThan(0));

      // Position 4 should have a benefit (negative)
      expect(netCost4, lessThan(0));

      // The cost and benefit should be symmetric
      expect(netCost0.abs(), closeTo(netCost4.abs(), 0.01));
    });

    test('gets recipient position for each month', () {
      const memberCount = 5;

      // Month 1 → Position 0
      expect(PaymentCalculator.getRecipientPosition(1, memberCount), equals(0));

      // Month 2 → Position 1
      expect(PaymentCalculator.getRecipientPosition(2, memberCount), equals(1));

      // Month 5 → Position 4
      expect(PaymentCalculator.getRecipientPosition(5, memberCount), equals(4));

      // Month 6 → Position 0 (cycles back)
      expect(PaymentCalculator.getRecipientPosition(6, memberCount), equals(0));
    });

    test('gets contribution breakdown', () {
      const totalPool = 2000.0;
      const memberCount = 5;

      final breakdown = PaymentCalculator.getContributionBreakdown(
        totalPoolAmount: totalPool,
        memberCount: memberCount,
      );

      expect(breakdown.length, equals(5));

      // Verify each position has the correct data
      for (int position = 0; position < memberCount; position++) {
        expect(breakdown[position]!['position'], equals(position));
        expect(breakdown[position]!['monthNumber'], equals(position + 1));
        expect(breakdown[position]!['amountReceived'], equals(totalPool));

        // Verify the net cost calculation
        final netCost = breakdown[position]!['netCost'] as double;
        final totalContribution =
            breakdown[position]!['totalContribution'] as double;
        expect(netCost, closeTo(totalContribution - totalPool, 0.01));
      }

      // Print breakdown for visibility
      print('\nContribution Breakdown:');
      print('═' * 80);
      for (final entry in breakdown.entries) {
        final data = entry.value;
        print(
            'Position ${data['position']} (Receives in Month ${data['monthNumber']}):');
        print(
            '  Monthly Payment: \$${(data['monthlyContribution'] as double).toStringAsFixed(2)}');
        print(
            '  Total Paid: \$${(data['totalContribution'] as double).toStringAsFixed(2)}');
        print('  Amount Received: \$${data['amountReceived']}');
        print(
            '  Net Cost: \$${(data['netCost'] as double).toStringAsFixed(2)}');
        print('-' * 80);
      }
    });

    test('handles edge cases', () {
      // Zero members
      final zeroMembers = PaymentCalculator.calculateMonthlyContribution(
        totalPoolAmount: 2000.0,
        memberCount: 0,
        position: 0,
      );
      expect(zeroMembers, equals(0.0));

      // Invalid position
      final invalidPosition = PaymentCalculator.calculateMonthlyContribution(
        totalPoolAmount: 2000.0,
        memberCount: 5,
        position: 10,
      );
      expect(invalidPosition, equals(0.0));

      // Single member (should pay the full amount)
      final singleMember = PaymentCalculator.calculateMonthlyContribution(
        totalPoolAmount: 2000.0,
        memberCount: 1,
        position: 0,
      );
      expect(singleMember, closeTo(2000.0, 0.01));
    });

    test('works with different pool amounts', () {
      // Test with €2000 (like in the example image)
      final euro2000 = PaymentCalculator.calculateAllContributions(
        totalPoolAmount: 2000.0,
        memberCount: 5,
      );

      print('\n€2000 Pool with 5 Members:');
      for (int i = 0; i < euro2000.length; i++) {
        print('Position $i: €${euro2000[i].toStringAsFixed(2)}');
      }

      // Verify the pattern matches the image (should be close to 430, 415, 400, 385, 370)
      expect(euro2000[0], closeTo(430.0, 1.0));
      expect(euro2000[2], closeTo(400.0, 1.0));
      expect(euro2000[4], closeTo(370.0, 1.0));
    });

    test('works with different member counts', () {
      const totalPool = 2000.0;

      // Test with 3 members
      final members3 = PaymentCalculator.calculateAllContributions(
        totalPoolAmount: totalPool,
        memberCount: 3,
      );
      expect(members3.length, equals(3));
      expect(members3.reduce((a, b) => a + b), closeTo(totalPool, 0.01));

      // Test with 10 members
      final members10 = PaymentCalculator.calculateAllContributions(
        totalPoolAmount: totalPool,
        memberCount: 10,
      );
      expect(members10.length, equals(10));
      expect(members10.reduce((a, b) => a + b), closeTo(totalPool, 0.01));
    });
  });
}
