import 'package:flutter/cupertino.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/theme/colors.dart';
import 'package:pay_app/widgets/profile_circle.dart';
// import 'package:pay_app/utils/date.dart';

class GroupListItem extends StatelessWidget {
  final Group group;
  final Function(Group) onTap;

  const GroupListItem({
    super.key,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const circleSize = 60.0;

    return CupertinoButton(
      padding: EdgeInsets.symmetric(vertical: 4),
      onPressed: () => onTap(group),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ProfileCircle(
              imageUrl: 'assets/icons/shop.png', // Default group icon
              size: circleSize,
              padding: 2,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12),
            Details(
              group: group,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MemberCountIndicator(memberCount: group.memberCount),
                const SizedBox(height: 8),
                TimeAgo(lastMessageAt: group.updatedAt),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Icon(
                  CupertinoIcons.chevron_right,
                  color: iconColor,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class Details extends StatelessWidget {
  final Group group;

  const Details({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.group,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 4),
              Name(name: group.name),
            ],
          ),
          const SizedBox(height: 4),
          AmountDescription(
            amount: group.amount,
            description: group.description,
          ),
        ],
      ),
    );
  }
}

class Name extends StatelessWidget {
  final String name;

  const Name({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF14023F),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class AmountDescription extends StatelessWidget {
  final String amount;
  final String? description;

  const AmountDescription({
    super.key,
    required this.amount,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '€${amount}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF14023F),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class MemberCountIndicator extends StatelessWidget {
  final int memberCount;

  const MemberCountIndicator({
    super.key,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$memberCount members',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: CupertinoColors.systemBlue,
        ),
      ),
    );
  }
}

class TimeAgo extends StatelessWidget {
  final DateTime lastMessageAt;

  const TimeAgo({super.key, required this.lastMessageAt});

  @override
  Widget build(BuildContext context) {
    // Simple time formatting - you can implement proper time ago formatting later
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);

    String timeText;
    if (difference.inDays > 0) {
      timeText = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeText = '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      timeText = '${difference.inMinutes}m ago';
    } else {
      timeText = 'now';
    }

    return Text(
      timeText,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF6B7280),
      ),
    );
  }
}
