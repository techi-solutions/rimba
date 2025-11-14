import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/state/groups/groups.dart';

class GroupJoinScreen extends StatefulWidget {
  final String groupId;
  final String? groupName;

  const GroupJoinScreen({
    super.key,
    required this.groupId,
    this.groupName,
  });

  @override
  State<GroupJoinScreen> createState() => _GroupJoinScreenState();
}

class _GroupJoinScreenState extends State<GroupJoinScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  Group? _group;
  String? _error;
  bool _alreadyMember = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroup();
    });
  }

  Future<void> _loadGroup() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final groupsState = context.read<GroupsState>();
      final group = await groupsState.getGroupById(widget.groupId);

      if (group == null) {
        setState(() {
          _error = 'Group not found';
          _isLoading = false;
        });
        return;
      }

      final userAddress = groupsState.userAccountAddress;
      if (userAddress != null) {
        await groupsState.selectGroup(widget.groupId);
        final members = groupsState.currentGroupMembers;
        _alreadyMember = members.any((member) =>
            member.contactAccount.toLowerCase() == userAddress.toLowerCase());
      }

      setState(() {
        _group = group;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load group: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    if (_group == null) return;

    try {
      setState(() {
        _isJoining = true;
        _error = null;
      });

      final groupsState = context.read<GroupsState>();
      final userAddress = groupsState.userAccountAddress;

      if (userAddress == null) {
        setState(() {
          _error = 'User not logged in';
          _isJoining = false;
        });
        return;
      }

      // Select the group first
      await groupsState.selectGroup(widget.groupId);

      // Add the user as a member
      final newMember = await groupsState.addGroupMember(userAddress);

      if (newMember != null) {
        // Successfully joined - show success and navigate to group
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        setState(() {
          _error = groupsState.error ?? 'Failed to join group';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to join group: $e';
      });
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success!'),
        content: Text('You have joined "${_group!.name}"'),
        actions: [
          CupertinoDialogAction(
            child: const Text('View Group'),
            onPressed: () {
              Navigator.pop(context);
              context.go('/groups/${widget.groupId}');
            },
          ),
        ],
      ),
    );
  }

  void _navigateToGroup() {
    context.go('/groups/${widget.groupId}');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.groupName ?? 'Join Group'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Cancel'),
          onPressed: () => context.go('/home'),
        ),
      ),
      child: SafeArea(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                child: const Text('Go to Home'),
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      );
    }

    if (_group == null) {
      return const Center(
        child: Text('Group not found'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group icon
          Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              CupertinoIcons.group_solid,
              size: 50,
              color: CupertinoColors.systemGrey,
            ),
          ),

          // Group name
          Text(
            _group!.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Group description
          if (_group!.description != null && _group!.description!.isNotEmpty)
            Text(
              _group!.description!,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 24),

          // Group info cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: CupertinoIcons.person_2,
                  label: 'Members',
                  value: '${_group!.memberCount}',
                ),
                _buildInfoItem(
                  icon: CupertinoIcons.money_dollar_circle,
                  label: 'Target Amount',
                  value: _group!.amount,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Join or View button
          if (_alreadyMember) ...[
            const Text(
              'You are already a member of this group',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              child: const Text('View Group'),
              onPressed: _navigateToGroup,
            ),
          ] else ...[
            CupertinoButton.filled(
              onPressed: _isJoining ? null : _joinGroup,
              child: _isJoining
                  ? const CupertinoActivityIndicator(
                      color: CupertinoColors.white)
                  : const Text('Join Group'),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              child: const Text('Maybe Later'),
              onPressed: () => context.go('/home'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: CupertinoColors.activeBlue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}
