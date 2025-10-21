import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/theme/colors.dart';
import 'package:pay_app/utils/payment_calc.dart';

class GroupDetailHeader extends StatelessWidget {
  final Group group;

  const GroupDetailHeader({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final members = groupsState.currentGroupMembers;
        final userAccount = groupsState.userAccountAddress;
        final monthlyAmount = double.parse(group.amount);

        GroupMember? userMember;
        try {
          userMember = members.firstWhere(
            (member) => member.contactAccount == userAccount,
          );
        } catch (e) {
          userMember = null;
        }

        // Calculate user's monthly payment
        double userMonthlyPayment = 0.0;
        if (userMember != null && members.isNotEmpty) {
          userMonthlyPayment = PaymentCalculator.calculateMonthlyContribution(
            totalPoolAmount: monthlyAmount,
            memberCount: members.length,
            position: userMember.payoutPosition,
          );
        }

        return Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mutedColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (group.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  group.description!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: textMutedColor,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.money_dollar_circle,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${group.amount} per month',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.person_2,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${group.memberCount} members • ${group.memberCount} months',
                    style: const TextStyle(
                      fontSize: 16,
                      color: textMutedColor,
                    ),
                  ),
                ],
              ),
              if (userMonthlyPayment > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.creditcard,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Your monthly payment: \$${userMonthlyPayment.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
