// Simple lending groups state - separate from main app state management
// Uses local in-memory data for testing

import 'package:flutter/cupertino.dart';
import 'package:rimba/models/simple_lending_group.dart';
import 'package:rimba/services/local_lending_data.dart';

class SimpleLendingState with ChangeNotifier {
  final LocalLendingDataService _dataService = LocalLendingDataService();

  List<SimpleLendingGroup> _groups = [];
  bool _loading = false;

  // Getters
  List<SimpleLendingGroup> get groups => _groups;
  bool get loading => _loading;
  bool get hasGroups => _groups.isNotEmpty;

  // Initialize and load data
  void initialize() {
    _loadGroups();
  }

  void _loadGroups() {
    _loading = true;
    notifyListeners();

    try {
      _groups = _dataService.getAllGroups();
    } catch (e) {
      debugPrint('Error loading lending groups: $e');
      _groups = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Refresh data
  void refresh() {
    _loadGroups();
  }

  // Add a new test group
  void addTestGroup() {
    final newGroup = SimpleLendingGroup(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Test Group ${_groups.length + 1}',
      description: 'A test group created from the app',
      status: SimpleGroupStatus.forming,
      baseAmount: 150.0,
      totalMembers: 4,
      currentMembers: 1,
      totalRounds: 4,
      currentRound: 1,
      members: [
        SimpleMember(
          name: 'Test User',
          username: 'test_user',
          monthlyAmount: 150.0,
          isAdmin: true,
        ),
      ],
    );

    _dataService.addGroup(newGroup);
    _loadGroups();
  }

  // Reset all data
  void resetData() {
    _dataService.resetData();
    _loadGroups();
  }
}

