import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/theme/colors.dart';


/// Shows monthly progress, recipients, and payment status
class GroupTimeline extends StatelessWidget {
  final Group group;

  const GroupTimeline({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final members = groupsState.currentGroupMembers;
        final timelineData = _calculateTimelineData(members);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineHeader(timelineData),
              const SizedBox(height: 16),
              ...timelineData['months'].map<Widget>((month) => _buildMonthCard(month)),
            ],
          ),
        );
      },
    );
  }

  /// Calculates timeline data for the group
  Map<String, dynamic> _calculateTimelineData(List<GroupMember> members) {
    final totalMonths = group.memberCount;
    final monthlyAmount = double.parse(group.amount);
    final months = <Map<String, dynamic>>[];
    
    for (int i = 0; i < totalMonths; i++) {
      final monthNumber = i + 1;
      final monthData = _createMonthData(monthNumber, members, monthlyAmount);
      months.add(monthData);
    }
    
    return {
      'months': months,
      'totalMonths': totalMonths,
      'completedMonths': months.where((m) => m['isCompleted']).length,
    };
  }

  /// Creates data for a specific month
  Map<String, dynamic> _createMonthData(int monthNumber, List<GroupMember> members, double monthlyAmount) {
    final recipient = members[(monthNumber - 1) % members.length];
    final isCompleted = _isMonthCompleted(monthNumber);
    final paidMembers = _getPaidMembersForMonth(monthNumber, members);
    
    return {
      'monthNumber': monthNumber,
      'recipient': recipient,
      'amount': monthlyAmount,
      'isCompleted': isCompleted,
      'paidMembers': paidMembers,
      'totalPaid': paidMembers.length,
      'totalMembers': members.length,
    };
  }

  /// Checks if a month is completed
  bool _isMonthCompleted(int monthNumber) {
    return monthNumber <= 2;
  }

  /// Gets members who have paid for a specific month
  List<GroupMember> _getPaidMembersForMonth(int monthNumber, List<GroupMember> members) {
    if (_isMonthCompleted(monthNumber)) {
      return members; // All members have paid for completed months
    }
    
    // For the month right after completed months, show some paid members
    if (monthNumber == 3) {
      return members.take(2).toList();
    }
    
    return []; // No payments for future months
  }

  /// Builds the timeline header with progress information
  Widget _buildTimelineHeader(Map<String, dynamic> timelineData) {
    final completedMonths = timelineData['completedMonths'] as int;
    final totalMonths = timelineData['totalMonths'] as int;
    final progressPercentage = _calculateProgressPercentage(completedMonths, totalMonths);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineTitle(),
          const SizedBox(height: 16),
          _buildProgressInfo(completedMonths, totalMonths, progressPercentage),
          const SizedBox(height: 12),
          _buildProgressBar(progressPercentage),
        ],
      ),
    );
  }

  /// Calculates progress percentage
  double _calculateProgressPercentage(int completed, int total) {
    return total > 0 ? (completed / total * 100) : 0.0;
  }

  /// Builds the timeline title
  Widget _buildTimelineTitle() {
    return const Text(
      'Payment Timeline',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds progress information row
  Widget _buildProgressInfo(int completedMonths, int totalMonths, double progressPercentage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$completedMonths of $totalMonths months completed',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${progressPercentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  /// Builds the progress bar
  Widget _buildProgressBar(double progressPercentage) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: mutedColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (progressPercentage / 100).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  /// Builds a month card
  Widget _buildMonthCard(Map<String, dynamic> month) {
    final isCompleted = month['isCompleted'] as bool;
    final recipient = month['recipient'] as GroupMember;
    final totalMembers = month['totalMembers'] as int;
    final totalPaid = month['totalPaid'] as int;
    final paidMembers = month['paidMembers'] as List<GroupMember>;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isCompleted ? primaryColor.withOpacity(0.1) : whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? primaryColor.withOpacity(0.3) : mutedColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(month, isCompleted),
          const SizedBox(height: 12),
          _buildRecipientInfo(recipient, month['amount']),
          const SizedBox(height: 12),
          _buildPaymentStatus(isCompleted, totalPaid, totalMembers),
          if (paidMembers.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPaidMembersList(paidMembers, isCompleted),
          ],
        ],
      ),
    );
  }

  /// Builds the month header
  Widget _buildMonthHeader(Map<String, dynamic> month, bool isCompleted) {
    return Row(
      children: [
        Icon(
          isCompleted ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.calendar,
          color: isCompleted ? primaryColor : textMutedColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Month ${month['monthNumber']}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isCompleted ? primaryColor : textColor,
          ),
        ),
        const Spacer(),
        if (isCompleted)
          const Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: primaryColor,
            size: 20,
          ),
      ],
    );
  }

  /// Builds recipient information
  Widget _buildRecipientInfo(GroupMember recipient, double amount) {
    return Row(
      children: [
        const Icon(
          CupertinoIcons.person_circle,
          color: primaryColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${recipient.memberName ?? 'Unknown'} receives \$${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds payment status
  Widget _buildPaymentStatus(bool isCompleted, int totalPaid, int totalMembers) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.money_dollar_circle,
          color: isCompleted ? primaryColor : textMutedColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          isCompleted 
              ? 'All members paid ✓'
              : '$totalPaid of $totalMembers members paid',
          style: TextStyle(
            fontSize: 14,
            color: isCompleted ? primaryColor : textMutedColor,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Builds the paid members list
  Widget _buildPaidMembersList(List<GroupMember> paidMembers, bool isCompleted) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: paidMembers.map((member) => _buildPaidMemberChip(member, isCompleted)).toList(),
    );
  }

  /// Builds a paid member chip
  Widget _buildPaidMemberChip(GroupMember member, bool isCompleted) {
    final chipColor = isCompleted ? primaryColor : warningColor;
    final icon = isCompleted ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.clock;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: chipColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            member.memberName ?? 'Unknown',
            style: TextStyle(
              fontSize: 12,
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
