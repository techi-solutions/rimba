import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:pay_app/state/groups/groups.dart';
import 'package:pay_app/widgets/groups/groups_list.dart';
import 'package:pay_app/screens/groups/group_detail_modal.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch groups when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsState>().fetchGroups();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Groups'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showCreateGroupModal,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search groups...',
                onChanged: (value) {
                  context.read<GroupsState>().searchGroups(value);
                },
              ),
            ),
            // Groups list
            Expanded(
              child: const GroupsList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupModal() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const GroupDetailModal(),
    );
  }
}
