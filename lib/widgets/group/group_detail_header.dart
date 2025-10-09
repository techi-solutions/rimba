import 'package:flutter/cupertino.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/theme/colors.dart';

class GroupDetailHeader extends StatelessWidget {
  final Group group;

  const GroupDetailHeader({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
