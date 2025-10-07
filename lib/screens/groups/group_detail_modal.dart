import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/state/groups/groups.dart';

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
  final List<String> _memberAccounts = [];

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
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTrailingButton() {
    if (widget.group == null) return const SizedBox.shrink();

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
        Consumer<GroupsState>(
          builder: (context, groupsState, child) {
            if (widget.group != null && !_isEditing) {
              // Show members from state
              final members = groupsState.currentGroupMembers;
              if (members.isEmpty) {
                return const Text('No members found');
              }

              return Column(
                children: members
                    .map((member) => _buildMemberItem(
                          member.contactAccount,
                          onRemove: null, // Can't remove in view mode
                        ))
                    .toList(),
              );
            } else {
              // Show members from local list (create/edit mode)
              if (_memberAccounts.isEmpty) {
                return const Text('No members added yet');
              }

              return Column(
                children: _memberAccounts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final account = entry.value;
                  return _buildMemberItem(
                    account,
                    onRemove: () => _removeMember(index),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildMemberItem(String account, {VoidCallback? onRemove}) {
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
            child: Text(
              account,
              style: const TextStyle(fontSize: 14),
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
      final groupsState = context.read<GroupsState>();
      groupsState.selectGroup(widget.group!.id).then((_) {
        setState(() {
          _memberAccounts.clear();
          _memberAccounts.addAll(
            groupsState.currentGroupMembers
                .map((member) => member.contactAccount)
                .toList(),
          );
        });
      });
    }
  }

  void _addMember() {
    showCupertinoDialog(
      context: context,
      builder: (context) => _AddMemberDialog(
        onAdd: (account) {
          setState(() {
            _memberAccounts.add(account);
          });
        },
      ),
    );
  }

  void _removeMember(int index) {
    setState(() {
      _memberAccounts.removeAt(index);
    });
  }

  void _createGroup() async {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    if (_memberAccounts.isEmpty) {
      _showError('Please add at least one member');
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
      memberAccounts: _memberAccounts,
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

  void _updateGroup() async {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

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
  }

  Future<void> _updateMembers() async {
    if (widget.group == null) return;

    final groupsState = context.read<GroupsState>();
    final currentMembers = groupsState.currentGroupMembers
        .map((member) => member.contactAccount)
        .toList();

    // Remove members that are no longer in the list
    for (final member in currentMembers) {
      if (!_memberAccounts.contains(member)) {
        await groupsState.removeGroupMember(member);
      }
    }

    // Add new members
    for (final account in _memberAccounts) {
      if (!currentMembers.contains(account)) {
        await groupsState.addGroupMember(account);
      }
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
}

class _AddMemberDialog extends StatefulWidget {
  final Function(String) onAdd;

  const _AddMemberDialog({required this.onAdd});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final TextEditingController _accountController = TextEditingController();

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Add Member'),
      content: CupertinoTextField(
        controller: _accountController,
        placeholder: 'Enter account address',
        autofocus: true,
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          child: const Text('Add'),
          onPressed: () {
            if (_accountController.text.isNotEmpty) {
              widget.onAdd(_accountController.text);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
