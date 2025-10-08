import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/models/group.dart';

class GroupsList extends StatelessWidget {
  const GroupsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        if (groupsState.isLoading) {
          return const Center(
            child: CupertinoActivityIndicator(),
          );
        }

        if (groupsState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${groupsState.error}',
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    groupsState.clearError();
                    groupsState.fetchGroups();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final groups = groupsState.filteredGroups;

        if (groups.isEmpty) {
          return const Center(
            child: Text('No groups found'),
          );
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return GroupListItem(
              group: group,
              onTap: () => _showGroupDetail(context, group),
              onEdit: () => _showGroupDetail(context, group),
              onDelete: () =>
                  _showDeleteConfirmation(context, groupsState, group),
            );
          },
        );
      },
    );
  }

  void _showGroupDetail(BuildContext context, Group group) {
    final navigator = GoRouter.of(context);
    navigator.push('/groups/${group.id}');
  }

  void _showDeleteConfirmation(
    BuildContext context,
    GroupsState groupsState,
    Group group,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () {
              Navigator.of(context).pop();
              groupsState.deleteGroup(group.id);
            },
          ),
        ],
      ),
    );
  }
}

class GroupListItem extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GroupListItem({
    super.key,
    required this.group,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      title: Text(group.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.description != null) ...[
            Text(group.description!),
            const SizedBox(height: 4),
          ],
          Text(
            '${group.memberCount} members • €${group.amount}',
            style: const TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onEdit,
            child: const Icon(
              CupertinoIcons.pencil,
              color: CupertinoColors.systemBlue,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onDelete,
            child: const Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
