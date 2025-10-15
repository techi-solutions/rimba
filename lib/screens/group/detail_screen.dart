import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_extensions.dart';
import 'package:pay_app/screens/groups/group_detail_modal.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/widgets/group/group_detail_header.dart';
import 'package:pay_app/widgets/group/group_tab_bar.dart';
import 'package:pay_app/screens/group/components/group_timeline.dart';
import 'package:pay_app/screens/group/components/group_members.dart';

/// Screen displaying detailed information about a specific group
/// with timeline and member management tabs
class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  int _selectedTabIndex = 0;
  bool _hasLoadedGroup = false;

  @override
  void initState() {
    super.initState();
    // Load the group when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroup();
    });
  }

  Future<void> _loadGroup() async {
    await context.read<GroupsState>().selectGroup(widget.groupId);
    if (mounted) {
      setState(() {
        _hasLoadedGroup = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoadedGroup) {
      return const CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Loading...'),
        ),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    return Consumer<GroupsState>(
      builder: (context, groupsState, child) {
        if (groupsState.isLoading) {
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('Loading...'),
            ),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        if (groupsState.error != null) {
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Error'),
            ),
            child: Center(
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
                      _loadGroup();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final group = groupsState.selectedGroup;
        if (group == null) {
          return CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Group Not Found'),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Group not found'),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () {
                      _loadGroup();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final isCreator = group.isCreator(groupsState.userAccountAddress);

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(group.name),
            trailing: isCreator
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _editGroup(group),
                    child: const Text('Edit'),
                  )
                : null,
          ),
          child: SafeArea(
            child: Column(
              children: [
                GroupDetailHeader(group: group),
                GroupTabBar(
                  selectedIndex: _selectedTabIndex,
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      GroupTimeline(group: group),
                      GroupMembers(group: group),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editGroup(Group group) {
    final groupsState = context.read<GroupsState>();

    showCupertinoModalPopup(
      context: context,
      useRootNavigator: true,
      builder: (modalContext) => ChangeNotifierProvider.value(
        value: groupsState,
        child: GroupDetailModal(group: group),
      ),
    );
  }
}
