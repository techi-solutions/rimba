import 'package:flutter/cupertino.dart';
import 'package:pay_app/models/group_request.dart';
import 'package:pay_app/theme/colors.dart';
import 'package:pay_app/widgets/profile_circle.dart';

class GroupRequestListItem extends StatelessWidget {
  final GroupRequest request;
  final Function(String) onAccept;
  final Function(String) onDecline;

  const GroupRequestListItem({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    const circleSize = 60.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ProfileCircle(
            imageUrl: 'assets/icons/shop.png', // Default group icon
            size: circleSize,
            padding: 2,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RequestDetails(request: request),
          ),
          const SizedBox(width: 12),
          ActionButtons(
            requestId: request.id,
            onAccept: onAccept,
            onDecline: onDecline,
          ),
        ],
      ),
    );
  }
}

class RequestDetails extends StatelessWidget {
  final GroupRequest request;

  const RequestDetails({
    super.key,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            Expanded(
              child: Text(
                request.groupName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF14023F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Group invitation',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        if (request.groupDescription != null) ...[
          const SizedBox(height: 2),
          Text(
            request.groupDescription!,
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

class ActionButtons extends StatelessWidget {
  final String requestId;
  final Function(String) onAccept;
  final Function(String) onDecline;

  const ActionButtons({
    super.key,
    required this.requestId,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () => onDecline(requestId),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              CupertinoIcons.xmark,
              color: CupertinoColors.systemRed,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: const EdgeInsets.all(8),
          onPressed: () => onAccept(requestId),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              CupertinoIcons.checkmark,
              color: CupertinoColors.systemGreen,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
