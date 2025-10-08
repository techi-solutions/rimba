import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/theme/colors.dart';

class GroupMembers extends StatelessWidget {
  final Group group;

  const GroupMembers({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final members = groupsState.currentGroupMembers;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMembersHeader(),
              const SizedBox(height: 16),
              ...members.map<Widget>((member) => _buildMemberCard(member)),
              const SizedBox(height: 16),
              _buildAddMemberButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.person_2,
            color: primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Member Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${group.memberCount} members',
            style: const TextStyle(
              fontSize: 14,
              color: textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(GroupMember member) {
    final memberData = _calculateMemberData(member);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mutedColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.person_circle,
                color: primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.memberName ?? 'Unknown Member',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.contactAccount,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textMutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildMemberActions(member),
            ],
          ),
          const SizedBox(height: 12),
          _buildMemberPaymentInfo(member, memberData),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateMemberData(GroupMember member) {
    final expectedAmount = group.memberCount > 0 
        ? double.parse(group.amount) / group.memberCount 
        : 0.0;
    final contributionAmount = double.parse(member.contributionAmount);
    final isFullyPaid = contributionAmount >= expectedAmount;
    final contributionPercentage = expectedAmount > 0 
        ? (contributionAmount / expectedAmount * 100)
        : 0.0;

    return {
      'isFullyPaid': isFullyPaid,
      'contributionPercentage': contributionPercentage,
      'contributionAmount': contributionAmount,
      'expectedAmount': expectedAmount,
    };
  }

  Widget _buildMemberActions(GroupMember member) {
    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _editMember(member),
          child: const Icon(
            CupertinoIcons.pencil,
            color: primaryColor,
            size: 20,
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _removeMember(member),
          child: const Icon(
            CupertinoIcons.delete,
            color: dangerColor,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberPaymentInfo(GroupMember member, Map<String, dynamic> memberData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Payment: \$${memberData['expectedAmount'].toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Paid: \$${member.contributionAmount}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: memberData['isFullyPaid'] ? primaryColor : textMutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: mutedColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (memberData['contributionPercentage'] / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: memberData['isFullyPaid'] ? primaryColor : warningColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMemberButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: _addMember,
        child: const Text('Add Member'),
      ),
    );
  }

  void _addMember() {
    HapticFeedback.lightImpact();
  }

  void _editMember(GroupMember member) {
    HapticFeedback.lightImpact();
  }

  void _removeMember(GroupMember member) {
    HapticFeedback.lightImpact();
  }
}
