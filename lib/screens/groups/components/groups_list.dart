import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_extensions.dart';

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
        final searchQuery = groupsState.searchQuery;

        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.group,
                    size: 80,
                    color: CupertinoColors.systemGrey3,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    searchQuery.isEmpty ? 'No Groups Yet' : 'No Groups Found',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    searchQuery.isEmpty
                        ? 'Create your first group to start\nsplitting payments with friends'
                        : 'Try searching with a different keyword',
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.systemGrey,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (searchQuery.isEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            CupertinoIcons.arrow_up_circle_fill,
                            color: CupertinoColors.activeBlue,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Tap the + button above to create',
                            style: TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.label,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final isCreator = group.isCreator(groupsState.userAccountAddress);
            return GroupListItem(
              group: group,
              isCreator: isCreator,
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
  final bool isCreator;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const GroupListItem({
    super.key,
    required this.group,
    required this.isCreator,
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
      trailing: isCreator
          ? Row(
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
            )
          : null,
      onTap: onTap,
    );
  }
}
