import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_member.dart';

class GroupsService {
  // Mock data for groups
  static final List<Group> _mockGroups = [
    Group.create(
      id: '1',
      name: 'Weekend Trip',
      description: 'Split costs for our weekend getaway',
      amount: '250.00',
      memberCount: 4,
    ),
    Group.create(
      id: '2',
      name: 'Office Lunch',
      description: 'Team lunch expenses',
      amount: '85.50',
      memberCount: 6,
    ),
    Group.create(
      id: '3',
      name: 'Birthday Party',
      description: 'Sarah\'s birthday celebration',
      amount: '320.75',
      memberCount: 8,
    ),
    Group.create(
      id: '4',
      name: 'Grocery Shopping',
      description: 'Shared household groceries',
      amount: '156.30',
      memberCount: 3,
    ),
    Group.create(
      id: '5',
      name: 'Concert Tickets',
      description: 'Music festival tickets and transport',
      amount: '180.00',
      memberCount: 5,
    ),
  ];

  // Mock data for group members
  static final List<GroupMember> _mockGroupMembers = [
    GroupMember.create(
        groupId: '1',
        contactAccount: '0x1234567890abcdef1234567890abcdef12345678',
        memberName: 'Alice Johnson',
        contributionAmount: '75.00'),
    GroupMember.create(
        groupId: '1',
        contactAccount: '0x2345678901bcdef1234567890abcdef1234567890',
        memberName: 'Bob Smith',
        contributionAmount: '60.00'),
    GroupMember.create(
        groupId: '1',
        contactAccount: '0x3456789012cdef1234567890abcdef12345678901',
        memberName: 'Carol Davis',
        contributionAmount: '55.00'),
    GroupMember.create(
        groupId: '1',
        contactAccount: '0x4567890123def1234567890abcdef123456789012',
        memberName: 'David Wilson',
        contributionAmount: '60.00'),
    
    // Office Lunch members
    GroupMember.create(
        groupId: '2',
        contactAccount: '0x5678901234ef1234567890abcdef1234567890123',
        memberName: 'Emma Brown',
        contributionAmount: '15.50'),
    GroupMember.create(
        groupId: '2',
        contactAccount: '0x6789012345f1234567890abcdef12345678901234',
        memberName: 'Frank Miller',
        contributionAmount: '12.00'),
    GroupMember.create(
        groupId: '2',
        contactAccount: '0x78901234561234567890abcdef123456789012345',
        memberName: 'Grace Lee',
        contributionAmount: '18.00'),
    GroupMember.create(
        groupId: '2',
        contactAccount: '0x8901234567234567890abcdef1234567890123456',
        memberName: 'Henry Taylor',
        contributionAmount: '14.00'),
    GroupMember.create(
        groupId: '2',
        contactAccount: '0x901234567834567890abcdef12345678901234567',
        memberName: 'Ivy Chen',
        contributionAmount: '16.00'),
    GroupMember.create(
        groupId: '2',
        contactAccount: '0x01234567894567890abcdef123456789012345678',
        memberName: 'Jack Anderson',
        contributionAmount: '10.00'),
    
    // Birthday Party members
    GroupMember.create(
        groupId: '3',
        contactAccount: '0x1234567890567890abcdef1234567890123456789',
        memberName: 'Sarah Williams',
        contributionAmount: '0.00'), // Birthday girl
    GroupMember.create(
        groupId: '3',
        contactAccount: '0x234567890167890abcdef12345678901234567890',
        memberName: 'Kevin Martinez',
        contributionAmount: '45.00'),
    GroupMember.create(
        groupId: '3',
        contactAccount: '0x34567890127890abcdef123456789012345678901',
        memberName: 'Lisa Garcia',
        contributionAmount: '40.00'),
    GroupMember.create(
        groupId: '3',
        contactAccount: '0x4567890123890abcdef1234567890123456789012',
        memberName: 'Mike Rodriguez',
        contributionAmount: '35.00'),
    GroupMember.create(
        groupId: '3',
        contactAccount: '0x567890123490abcdef12345678901234567890123',
        memberName: 'Nancy Thompson',
        contributionAmount: '42.00'),
    GroupMember.create(
        groupId: '3',
        contactAccount: '0x67890123450abcdef123456789012345678901234',
        memberName: 'Oscar White',
        contributionAmount: '38.00'),
    GroupMember.create(
        groupId: '3',
        contactAccount: '0x7890123456abcdef1234567890123456789012345',
        memberName: 'Paula Harris',
        contributionAmount: '36.00'),
    GroupMember.create(
        groupId: '3',
        contactAccount: '0x8901234567bcdef12345678901234567890123456',
        memberName: 'Quinn Martin',
        contributionAmount: '44.75'),
    
    // Grocery Shopping members
    GroupMember.create(
        groupId: '4',
        contactAccount: '0x9012345678cdef123456789012345678901234567',
        memberName: 'Rachel Green',
        contributionAmount: '52.10'),
    GroupMember.create(
        groupId: '4',
        contactAccount: '0x0123456789def1234567890123456789012345678',
        memberName: 'Steve Cooper',
        contributionAmount: '48.20'),
    GroupMember.create(
        groupId: '4',
        contactAccount: '0x1234567890ef12345678901234567890123456789',
        memberName: 'Tina Adams',
        contributionAmount: '56.00'),
    
    // Concert Tickets members
    GroupMember.create(
        groupId: '5',
        contactAccount: '0x2345678901f123456789012345678901234567890',
        memberName: 'Ulysses Bell',
        contributionAmount: '36.00'),
    GroupMember.create(
        groupId: '5',
        contactAccount: '0x34567890121234567890123456789012345678901',
        memberName: 'Victoria Clark',
        contributionAmount: '36.00'),
    GroupMember.create(
        groupId: '5',
        contactAccount: '0x45678901232345678901234567890123456789012',
        memberName: 'William Turner',
        contributionAmount: '36.00'),
    GroupMember.create(
        groupId: '5',
        contactAccount: '0x56789012343456789012345678901234567890123',
        memberName: 'Xavier Young',
        contributionAmount: '36.00'),
    GroupMember.create(
        groupId: '5',
        contactAccount: '0x67890123454567890123456789012345678901234',
        memberName: 'Yolanda King',
        contributionAmount: '36.00'),
  ];

  // Simulate network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Create a new group
  Future<Group> createGroup({
    required String name,
    String? description,
    required String amount,
    required List<String> memberAccounts,
  }) async {
    await _simulateDelay();

    final newId = (_mockGroups.length + 1).toString();
    final newGroup = Group.create(
      id: newId,
      name: name,
      description: description,
      amount: amount,
      memberCount: memberAccounts.length,
    );

    _mockGroups.add(newGroup);

    // Add group members
    for (final account in memberAccounts) {
      _mockGroupMembers.add(
        GroupMember.create(
          groupId: newId,
          contactAccount: account,
        ),
      );
    }

    return newGroup;
  }

  // Read all groups
  Future<List<Group>> getGroups() async {
    await _simulateDelay();
    return List.from(_mockGroups);
  }

  // Read a specific group by ID
  Future<Group?> getGroupById(String id) async {
    await _simulateDelay();
    try {
      return _mockGroups.firstWhere((group) => group.id == id);
    } catch (e) {
      return null;
    }
  }

  // Update a group
  Future<Group?> updateGroup({
    required String id,
    String? name,
    String? description,
    String? amount,
  }) async {
    await _simulateDelay();

    final index = _mockGroups.indexWhere((group) => group.id == id);
    if (index == -1) return null;

    final existingGroup = _mockGroups[index];
    final updatedGroup = existingGroup.copyWith(
      name: name,
      description: description,
      amount: amount,
      updatedAt: DateTime.now(),
    );

    _mockGroups[index] = updatedGroup;
    return updatedGroup;
  }

  // Delete a group
  Future<bool> deleteGroup(String id) async {
    await _simulateDelay();

    final index = _mockGroups.indexWhere((group) => group.id == id);
    if (index == -1) return false;

    _mockGroups.removeAt(index);

    // Remove associated group members
    _mockGroupMembers.removeWhere((member) => member.groupId == id);

    return true;
  }

  // Get group members for a specific group
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    await _simulateDelay();
    return _mockGroupMembers
        .where((member) => member.groupId == groupId)
        .toList();
  }

  // Add a member to a group
  Future<GroupMember?> addGroupMember({
    required String groupId,
    required String contactAccount,
    String? memberName,
    String contributionAmount = '0.00',
  }) async {
    await _simulateDelay();

    // Check if group exists
    final groupExists = _mockGroups.any((group) => group.id == groupId);
    if (!groupExists) return null;

    // Check if member already exists
    final memberExists = _mockGroupMembers.any(
      (member) =>
          member.groupId == groupId && member.contactAccount == contactAccount,
    );
    if (memberExists) return null;

    final newMember = GroupMember.create(
      groupId: groupId,
      contactAccount: contactAccount,
      memberName: memberName,
      contributionAmount: contributionAmount,
    );

    _mockGroupMembers.add(newMember);

    // Update group member count
    final groupIndex = _mockGroups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _mockGroups[groupIndex];
      final memberCount =
          _mockGroupMembers.where((m) => m.groupId == groupId).length;
      _mockGroups[groupIndex] = group.copyWith(
        memberCount: memberCount,
        updatedAt: DateTime.now(),
      );
    }

    return newMember;
  }

  // Remove a member from a group
  Future<bool> removeGroupMember({
    required String groupId,
    required String contactAccount,
  }) async {
    await _simulateDelay();

    final index = _mockGroupMembers.indexWhere(
      (member) =>
          member.groupId == groupId && member.contactAccount == contactAccount,
    );

    if (index == -1) return false;

    _mockGroupMembers.removeAt(index);

    // Update group member count
    final groupIndex = _mockGroups.indexWhere((group) => group.id == groupId);
    if (groupIndex != -1) {
      final group = _mockGroups[groupIndex];
      final memberCount =
          _mockGroupMembers.where((m) => m.groupId == groupId).length;
      _mockGroups[groupIndex] = group.copyWith(
        memberCount: memberCount,
        updatedAt: DateTime.now(),
      );
    }

    return true;
  }

  // Search groups by name or description
  Future<List<Group>> searchGroups(String query) async {
    await _simulateDelay();

    if (query.isEmpty) return getGroups();

    final lowercaseQuery = query.toLowerCase();
    return _mockGroups.where((group) {
      return group.name.toLowerCase().contains(lowercaseQuery) ||
          (group.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }
}
