import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: 16.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMembersHeader(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              if (members.length == 1 && isCreator) ...[
                _buildNeedMoreMembersBanner(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              ],
              Expanded(
                child: _buildReorderableMembersList(isCreator),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              _buildReadySection(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
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
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;

        return Container(
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_2,
                          color: primaryColor,
                          size: screenWidth * 0.05,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: Text(
                            'Member Management',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      '$memberCount members',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: textMutedColor,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_2,
                      color: primaryColor,
                      size: screenWidth * 0.05,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Member Management',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$memberCount members',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: CupertinoColors.systemOrange.withOpacity(0.3)),
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle,
                      color: CupertinoColors.systemOrange,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        'Add more members',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.01),
                Text(
                  'A group needs at least 2 members to start the payment cycle',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: textMutedColor,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  color: CupertinoColors.systemOrange,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add more members',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        'A group needs at least 2 members to start the payment cycle',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
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

  Widget _buildMemberCard(GroupMember member, bool isCreator,
      {bool isDraggable = true}) {
    final memberData = _calculateMemberData(member);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Container(
      key: Key('member_${member.contactAccount}_${member.payoutPosition}'),
      margin: EdgeInsets.only(bottom: screenWidth * 0.03),
      padding: EdgeInsets.all(screenWidth * 0.04),
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
              if (isDraggable && isCreator)
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: Icon(
                    CupertinoIcons.bars,
                    color: primaryColor,
                    size: screenWidth * 0.045,
                  ),
                )
              else
                SizedBox(width: screenWidth * 0.085),
              Icon(
                CupertinoIcons.person_circle,
                color: primaryColor,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSmallScreen) ...[
                      // Stack layout for small screens
                      Row(
                        children: [
                          Text(
                            member.memberName ?? 'Unknown Member',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.group
                              .isCreator(member.contactAccount)) ...[
                            SizedBox(width: screenWidth * 0.01),
                            Tooltip(
                              message: 'Group Admin',
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.005),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemYellow
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: CupertinoColors.systemYellow
                                        .withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.star_fill,
                                  size: screenWidth * 0.03,
                                  color: CupertinoColors.systemYellow,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      if (isSmallScreen) ...[
                        // Column layout for small screens - Ready badge below Month badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenWidth * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Month ${member.payoutPosition + 1}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.025,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            if (member.isReady) ...[
                              SizedBox(height: screenWidth * 0.01),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenWidth * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.checkmark_circle_fill,
                                      size: screenWidth * 0.03,
                                      color: primaryColor,
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Text(
                                      'Ready',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.025,
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
                      ] else ...[
                        // Row layout for larger screens - Ready badge next to Month badge
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenWidth * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Month ${member.payoutPosition + 1}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.025,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            if (member.isReady) ...[
                              SizedBox(width: screenWidth * 0.02),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenWidth * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.checkmark_circle_fill,
                                      size: screenWidth * 0.03,
                                      color: primaryColor,
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Text(
                                      'Ready',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.025,
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
                      ],
                    ] else ...[
                      // Row layout for larger screens
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    member.memberName ?? 'Unknown Member',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.group
                                    .isCreator(member.contactAccount)) ...[
                                  SizedBox(width: screenWidth * 0.01),
                                  Tooltip(
                                    message: 'Group Admin',
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.005),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemYellow
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: CupertinoColors.systemYellow
                                              .withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.star_fill,
                                        size: screenWidth * 0.03,
                                        color: CupertinoColors.systemYellow,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenWidth * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Month ${member.payoutPosition + 1}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          if (member.isReady) ...[
                            SizedBox(width: screenWidth * 0.02),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenWidth * 0.005,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    size: screenWidth * 0.03,
                                    color: primaryColor,
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    'Ready',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.025,
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
                    ],
                    SizedBox(height: screenWidth * 0.005),
                    Text(
                      member.contactAccount,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: textMutedColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isCreator) _buildMemberActions(member, member.isReady),
            ],
          ),
          SizedBox(height: screenWidth * 0.03),
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

  Widget _buildMemberActions(GroupMember member, bool isReady) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isReady ? null : () => _removeMember(member),
      child: Icon(
        CupertinoIcons.delete,
        color: isReady ? textMutedColor : dangerColor,
        size: 20,
      ),
    );
  }

  Widget _buildMemberPaymentInfo(
      GroupMember member, Map<String, dynamic> memberData) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isSmallScreen) ...[
          // Stack layout for small screens
          Text(
            'Monthly Payment: \$${memberData['expectedAmount'].toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Text(
            'Paid: \$${member.contributionAmount}',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.bold,
              color: memberData['isFullyPaid'] ? primaryColor : textMutedColor,
            ),
          ),
        ] else ...[
          // Row layout for larger screens
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Monthly Payment: \$${memberData['expectedAmount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'Paid: \$${member.contributionAmount}',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                  color:
                      memberData['isFullyPaid'] ? primaryColor : textMutedColor,
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: screenWidth * 0.02),
        Container(
          height: screenWidth * 0.01,
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

  Widget _buildReadySection() {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final members = groupsState.currentGroupMembers;
        final isAllReady = groupsState.areAllMembersReady();
        final readyCount = groupsState.getReadyCount();
        final isCurrentUserReady = groupsState.isCurrentUserReady();
        final screenWidth = MediaQuery.of(context).size.width;

        if (members.length < 2) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.03,
          ),
          decoration: BoxDecoration(
            color: isAllReady ? primaryColor.withOpacity(0.1) : backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAllReady ? primaryColor : primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAllReady
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.clock,
                color: isAllReady ? primaryColor : textMutedColor,
                size: screenWidth * 0.05,
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  '$readyCount/${members.length} ready',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: isAllReady ? primaryColor : textMutedColor,
                  ),
                ),
              ),
              if (isAllReady) ...[
                _buildStartPaymentButton(),
              ] else if (!isCurrentUserReady) ...[
                _buildReadyButton(),
              ] else ...[
                _buildUnmarkReadyButton(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadyButton() {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final isLoading = groupsState.isLoading;
        final userAccount = groupsState.userAccountAddress;
        final screenWidth = MediaQuery.of(context).size.width;

        return CupertinoButton.filled(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.02,
          ),
          onPressed: isLoading ? null : () => _markAsReady(userAccount!),
          child: isLoading
              ? CupertinoActivityIndicator(
                  radius: screenWidth * 0.03,
                )
              : Text(
                  'Ready',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildUnmarkReadyButton() {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final isLoading = groupsState.isLoading;
        final userAccount = groupsState.userAccountAddress;
        final screenWidth = MediaQuery.of(context).size.width;

        return CupertinoButton(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.02,
          ),
          color: CupertinoColors.systemGrey5,
          onPressed: isLoading ? null : () => _unmarkAsReady(userAccount!),
          child: isLoading
              ? CupertinoActivityIndicator(
                  radius: screenWidth * 0.03,
                  color: primaryColor,
                )
              : Text(
                  'Unmark Ready',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStartPaymentButton() {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final isLoading = groupsState.isLoading;
        final isCreator =
            widget.group.isCreator(groupsState.userAccountAddress);
        final screenWidth = MediaQuery.of(context).size.width;

        if (!isCreator) {
          return const SizedBox.shrink();
        }

        return CupertinoButton.filled(
          color: primaryColor,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.02,
          ),
          onPressed: isLoading ? null : _startPaymentFlow,
          child: isLoading
              ? CupertinoActivityIndicator(
                  radius: screenWidth * 0.03,
                )
              : Text(
                  'Start',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildReorderableMembersList(bool isCreator) {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final members = groupsState.currentGroupMembers;
        final isAllReady = groupsState.areAllMembersReady();

        // If all members are ready, show regular list without reordering
        if (isAllReady) {
          return Column(
            children: members
                .map<Widget>((member) =>
                    _buildMemberCard(member, isCreator, isDraggable: false))
                .toList(),
          );
        }

        // If not creator, show regular list
        if (!isCreator) {
          return Column(
            children: members
                .map<Widget>((member) =>
                    _buildMemberCard(member, isCreator, isDraggable: false))
                .toList(),
          );
        }

        return ReorderableListView(
          key: ValueKey(
              'members_${members.length}_${members.map((m) => m.payoutPosition).join('_')}'),
          onReorder: (oldIndex, newIndex) =>
              _onReorderMembers(oldIndex, newIndex),
          children: members
              .map<Widget>((member) => _buildMemberCard(member, isCreator,
                  isDraggable: !member.isReady))
              .toList(),
        );
      },
    );
  }

  Widget _buildAddMemberButton() {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        final isAllReady = groupsState.areAllMembersReady();
        final screenWidth = MediaQuery.of(context).size.width;

        return SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            onPressed: isAllReady ? null : _addMember,
            child: Text(
              isAllReady ? 'All Members Ready' : 'Add Member',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onReorderMembers(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    HapticFeedback.lightImpact();

    final groupsState = context.read<GroupsState>();

    // Get the current members list from the state
    final currentMembers = groupsState.currentGroupMembers;

    // Validate indices
    if (oldIndex < 0 || oldIndex >= currentMembers.length) {
      return;
    }

    // Adjust newIndex to be within bounds
    if (newIndex < 0) {
      newIndex = 0;
    } else if (newIndex >= currentMembers.length) {
      newIndex = currentMembers.length - 1;
    }

    // Create a copy of the members list
    final newOrder = List<GroupMember>.from(currentMembers);

    // Remove the item from the old position
    final item = newOrder.removeAt(oldIndex);

    // Insert it at the new position
    newOrder.insert(newIndex, item);

    final success = await groupsState.reorderGroupMembers(newOrder);

    if (mounted && !success) {
      // Show error if reordering failed
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to reorder members. Please try again.'),
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

  void _markAsReady(String userAccount) async {
    HapticFeedback.lightImpact();

    final groupsState = context.read<GroupsState>();
    final success =
        await groupsState.markMemberReady(widget.group.id, userAccount);

    if (mounted) {
      if (success) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Ready!'),
            content:
                const Text('You have marked yourself as ready for payments.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to mark as ready. Please try again.'),
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

  void _unmarkAsReady(String userAccount) async {
    HapticFeedback.lightImpact();

    final groupsState = context.read<GroupsState>();
    bool success = false;

    try {
      await groupsState.updateMemberReadyStatus(
        groupId: widget.group.id,
        userAddress: userAccount,
        isReady: false,
      );
      success = true;
    } catch (e) {
      debugPrint('Error unmarking as ready: $e');
      success = false;
    }

    if (mounted) {
      if (success) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Unmarked'),
            content: const Text('You have unmarked yourself as ready.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to unmark as ready. Please try again.'),
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

  void _startPaymentFlow() async {
    HapticFeedback.lightImpact();

    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Start Payment Flow'),
        content: const Text(
          'This will begin the payment cycle. The first person will receive their payout. Are you sure?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            child: const Text('Start'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final groupsState = context.read<GroupsState>();
    final success = await groupsState.startPaymentFlow();

    if (mounted) {
      if (success) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Payment Flow Started'),
            content: const Text(
              'The payment cycle has begun! The first person will receive their payout.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(
              groupsState.error ??
                  'Failed to start payment flow. Please try again.',
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
    }
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
