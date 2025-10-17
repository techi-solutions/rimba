import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_extensions.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/state/contacts/contacts.dart';
import 'package:pay_app/theme/colors.dart';
import 'package:pay_app/screens/group/add_member_modal.dart';
import 'package:pay_app/utils/payment_calc.dart';

class GroupMembers extends StatefulWidget {
  final Group group;

  const GroupMembers({
    super.key,
    required this.group,
  });

  @override
  State<GroupMembers> createState() => _GroupMembersState();
}

class _GroupMembersState extends State<GroupMembers> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final members = groupsState.currentGroupMembers;
        final isCreator =
            widget.group.isCreator(groupsState.userAccountAddress);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMembersHeader(),
              const SizedBox(height: 16),
              if (members.length == 1 && isCreator) ...[
                _buildNeedMoreMembersBanner(),
                const SizedBox(height: 16),
              ],
              ...members
                  .map<Widget>((member) => _buildMemberCard(member, isCreator)),
              const SizedBox(height: 16),
              if (isCreator) _buildAddMemberButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersHeader() {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final members = groupsState.currentGroupMembers;
        final memberCount =
            members.isNotEmpty ? members.length : widget.group.memberCount;

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
                '$memberCount members',
                style: const TextStyle(
                  fontSize: 14,
                  color: textMutedColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNeedMoreMembersBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: CupertinoColors.systemOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.systemOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add more members',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'A group needs at least 2 members to start the payment cycle',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(GroupMember member, bool isCreator) {
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
                    Row(
                      children: [
                        Text(
                          member.memberName ?? 'Unknown Member',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Month ${member.payoutPosition + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
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
              if (isCreator) _buildMemberActions(member),
            ],
          ),
          const SizedBox(height: 12),
          _buildMemberPaymentInfo(member, memberData),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateMemberData(GroupMember member) {
    final groupsState = context.read<GroupsState>();
    final members = groupsState.currentGroupMembers;
    final actualMemberCount =
        members.isNotEmpty ? members.length : widget.group.memberCount;

    final expectedAmount = actualMemberCount > 0
        ? PaymentCalculator.calculateMonthlyContribution(
            totalPoolAmount: double.parse(widget.group.amount),
            memberCount: actualMemberCount,
            position: member.payoutPosition,
          )
        : 0.0;

    final contributionAmount = double.parse(member.contributionAmount);
    final isFullyPaid = contributionAmount >= expectedAmount;
    final contributionPercentage =
        expectedAmount > 0 ? (contributionAmount / expectedAmount * 100) : 0.0;

    return {
      'isFullyPaid': isFullyPaid,
      'contributionPercentage': contributionPercentage,
      'contributionAmount': contributionAmount,
      'expectedAmount': expectedAmount,
      'payoutPosition': member.payoutPosition,
    };
  }

  Widget _buildMemberActions(GroupMember member) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _removeMember(member),
      child: const Icon(
        CupertinoIcons.delete,
        color: dangerColor,
        size: 20,
      ),
    );
  }

  Widget _buildMemberPaymentInfo(
      GroupMember member, Map<String, dynamic> memberData) {
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
                color:
                    memberData['isFullyPaid'] ? primaryColor : textMutedColor,
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
            widthFactor:
                (memberData['contributionPercentage'] / 100).clamp(0.0, 1.0),
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

  void _addMember() async {
    HapticFeedback.lightImpact();

    final groupsState = context.read<GroupsState>();
    final contactsState = context.read<ContactsState>();

    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => MultiProvider(
        providers: [
          ChangeNotifierProvider<GroupsState>.value(value: groupsState),
          ChangeNotifierProvider<ContactsState>.value(value: contactsState),
        ],
        child: AddMemberModal(
          onAdd: (accountOrUsername, displayName) async {
            try {
              await groupsState.sendGroupRequest(accountOrUsername);

              if (widget.group.id.isNotEmpty) {
                await groupsState.selectGroup(widget.group.id);
              }

              if (mounted) {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Success'),
                    content: Text(
                      'Group request sent to ${displayName ?? accountOrUsername}',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                // Show error message
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Error'),
                    content:
                        Text('Failed to send group request: ${e.toString()}'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _removeMember(GroupMember member) async {
    HapticFeedback.lightImpact();

    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.memberName ?? member.contactAccount} from this group?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Remove the member
    final groupsState = context.read<GroupsState>();
    final success = await groupsState.removeGroupMember(member.contactAccount);

    if (mounted) {
      if (success) {
        // Show success message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text(
              '${member.memberName ?? member.contactAccount} has been removed from the group',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );

        // Refresh the group details
        if (widget.group.id.isNotEmpty) {
          await groupsState.selectGroup(widget.group.id);
        }
      } else {
        // Show error message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to remove member. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }
}
