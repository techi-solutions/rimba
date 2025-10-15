import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_extensions.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/state/contacts/contacts.dart';
import 'package:pay_app/screens/group/add_member_modal.dart';

class GroupDetailModal extends StatefulWidget {
  final Group? group; // null for create, Group for edit/view

  const GroupDetailModal({
    super.key,
    this.group,
  });

  @override
  State<GroupDetailModal> createState() => _GroupDetailModalState();
}

class _GroupDetailModalState extends State<GroupDetailModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final List<String> _memberIds = [];
  final Map<String, String?> _memberNames = {};

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
      _amountController.text = widget.group!.amount;
      // Note: We'll load members separately
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreateMode = widget.group == null;
    final title = isCreateMode ? 'Create Group' : 'Group Details';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        trailing: _buildTrailingButton(),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupInfoSection(),
                    const SizedBox(height: 24),
                    _buildMembersSection(),
                    if (isCreateMode) ...[
                      const SizedBox(height: 24),
                      _buildCreateButton(),
                    ],
                    if (!isCreateMode &&
                        widget.group!.isCreator(context
                            .read<GroupsState>()
                            .userAccountAddress)) ...[
                      const SizedBox(height: 32),
                      _buildDeleteButton(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTrailingButton() {
    if (widget.group == null) return const SizedBox.shrink();

    // Only show edit button if user is the creator
    final groupsState = context.read<GroupsState>();
    if (!widget.group!.isCreator(groupsState.userAccountAddress)) {
      return const SizedBox.shrink();
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _toggleEditMode,
      child: Text(_isEditing ? 'Done' : 'Edit'),
    );
  }

  Widget _buildGroupInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Group Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Group name
        CupertinoTextField(
          controller: _nameController,
          placeholder: 'Group name',
          padding: const EdgeInsets.all(16),
          enabled: widget.group == null || _isEditing,
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.separator),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),

        // Description
        CupertinoTextField(
          controller: _descriptionController,
          placeholder: 'Description (optional)',
          padding: const EdgeInsets.all(16),
          enabled: widget.group == null || _isEditing,
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.separator),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),

        // Amount
        CupertinoTextField(
          controller: _amountController,
          placeholder: 'Amount (e.g., 100.00)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          padding: const EdgeInsets.all(16),
          enabled: widget.group == null || _isEditing,
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.separator),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.group == null || _isEditing)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addMember,
                child: const Text('Add Member'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMembersContent(),
      ],
    );
  }

  Widget _buildMembersContent() {
    try {
      final groupsState = Provider.of<GroupsState>(context, listen: false);

      if (widget.group != null && !_isEditing) {
        final members = groupsState.currentGroupMembers;
        if (members.isEmpty) {
          return const Text('No members found');
        }

        // Store member names for view mode
        for (final member in members) {
          _memberNames[member.contactAccount] = member.memberName;
        }

        return Column(
          children: members
              .map((member) => _buildMemberItem(
                    member.contactAccount,
                    onRemove: null,
                  ))
              .toList(),
        );
      }
    } catch (e) {}

    if (_memberIds.isEmpty) {
      return const Text('No members added yet');
    }

    return Column(
      children: _memberIds.asMap().entries.map((entry) {
        final index = entry.key;
        final account = entry.value;
        return _buildMemberItem(
          account,
          onRemove: () => _removeMember(index),
        );
      }).toList(),
    );
  }

  Widget _buildMemberItem(String account, {VoidCallback? onRemove}) {
    final displayName = _memberNames[account];
    final displayText = displayName ??
        '${account.substring(0, 6)}...${account.substring(account.length - 4)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (displayName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${account.substring(0, 6)}...${account.substring(account.length - 4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRemove != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onRemove,
              child: const Icon(
                CupertinoIcons.delete,
                color: CupertinoColors.systemRed,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        onPressed: _createGroup,
        child: const Text('Create Group'),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Column(
      children: [
        Container(
          height: 1,
          color: CupertinoColors.separator,
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemRed,
            onPressed: _deleteGroup,
            child: const Text(
              'Delete Group',
              style: TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });

    if (!_isEditing) {
      // Save changes
      _updateGroup();
    } else {
      // Load members for editing
      _loadMembersForEditing();
    }
  }

  void _loadMembersForEditing() {
    if (widget.group != null) {
      try {
        final groupsState = context.read<GroupsState>();
        groupsState.selectGroup(widget.group!.id).then((_) {
          setState(() {
            _memberIds.clear();
            _memberNames.clear();
            for (final member in groupsState.currentGroupMembers) {
              _memberIds.add(member.contactAccount);
              _memberNames[member.contactAccount] = member.memberName;
            }
          });
        });
      } catch (e) {
        setState(() {
          _memberIds.clear();
          _memberNames.clear();
        });
      }
    }
  }

  void _addMember() {
    // Get the ContactsState from the current context before showing the modal
    final contactsState = context.read<ContactsState>();

    showCupertinoModalPopup(
      context: context,
      builder: (modalContext) => ChangeNotifierProvider<ContactsState>.value(
        value: contactsState,
        child: AddMemberModal(
          onAdd: (accountOrUsername, displayName) {
            setState(() {
              _memberIds.add(accountOrUsername);
              _memberNames[accountOrUsername] = displayName;
            });
          },
        ),
      ),
    );
  }

  void _removeMember(int index) {
    setState(() {
      final account = _memberIds[index];
      _memberIds.removeAt(index);
      _memberNames.remove(account);
    });
  }

  void _createGroup() async {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final groupsState = context.read<GroupsState>();
    final success = await groupsState.createGroup(
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      amount: _amountController.text,
      memberIds: _memberIds,
    );

    setState(() {
      _isLoading = false;
    });

    if (success != null && mounted) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } else if (mounted) {
      _showError('Failed to create group');
    }
  }

  Future<void> _updateGroup() async {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groupsState = context.read<GroupsState>();

      final success = await groupsState.updateGroup(
        id: widget.group!.id,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        amount: _amountController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (success != null && mounted) {
        HapticFeedback.lightImpact();
        // Update members if they changed
        await _updateMembers();
      } else if (mounted) {
        _showError('Failed to update group');
      }
    } catch (e) {
      debugPrint('Error updating group: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showError('Failed to update group. Please try again.');
      }
    }
  }

  Future<void> _updateMembers() async {
    if (widget.group == null) return;

    try {
      final groupsState = context.read<GroupsState>();
      final currentMembers = groupsState.currentGroupMembers
          .map((member) => member.contactAccount)
          .toList();

      // Remove members that are no longer in the list
      for (final member in currentMembers) {
        if (!_memberIds.contains(member)) {
          await groupsState.removeGroupMember(member);
        }
      }

      // Send requests to new members
      for (final memberId in _memberIds) {
        if (!currentMembers.contains(memberId)) {
          try {
            await groupsState.sendGroupRequest(memberId);
          } catch (e) {
            debugPrint('Failed to send request to $memberId: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating members: $e');
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _deleteGroup() async {
    if (widget.group == null) return;

    // Show confirmation dialog
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${widget.group!.name}"? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    final groupsState = context.read<GroupsState>();
    final success = await groupsState.deleteGroup(widget.group!.id);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        HapticFeedback.lightImpact();
        // Close the modal
        Navigator.of(context).pop();
        // Show success message
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text('${widget.group!.name} has been deleted'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        _showError('Failed to delete group. Please try again.');
      }
    }
  }
}
