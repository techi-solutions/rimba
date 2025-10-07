// Local lending groups data service - completely separate from main app
// Uses in-memory storage for testing without interfering with existing DB

import 'package:rimba/models/simple_lending_group.dart';

class LocalLendingDataService {
  static final LocalLendingDataService _instance = LocalLendingDataService._internal();
  factory LocalLendingDataService() => _instance;
  LocalLendingDataService._internal();

  // In-memory storage
  List<SimpleLendingGroup> _groups = [];
  bool _initialized = false;

  // Initialize with test data
  void initialize() {
    if (_initialized) return;
    
    _groups = [
      SimpleLendingGroup(
        id: 'test_group_1',
        name: 'Friends Savings Circle',
        description: 'Monthly savings group for friends',
        imageUrl: 'https://picsum.photos/id/237/200/300',
        status: SimpleGroupStatus.active,
        baseAmount: 200.0,
        totalMembers: 5,
        currentMembers: 5,
        totalRounds: 5,
        currentRound: 2,
        members: [
          SimpleMember(
            name: 'Alice Johnson',
            username: 'alice_j',
            imageUrl: 'https://i.pravatar.cc/150?img=1',
            monthlyAmount: 240.0,
            isAdmin: true,
          ),
          SimpleMember(
            name: 'Bob Smith',
            username: 'bob_smith',
            imageUrl: 'https://i.pravatar.cc/150?img=2',
            monthlyAmount: 200.0,
          ),
          SimpleMember(
            name: 'Carol Davis',
            username: 'carol_d',
            imageUrl: 'https://i.pravatar.cc/150?img=3',
            monthlyAmount: 200.0,
          ),
          SimpleMember(
            name: 'David Wilson',
            username: 'david_w',
            imageUrl: 'https://i.pravatar.cc/150?img=4',
            monthlyAmount: 180.0,
          ),
          SimpleMember(
            name: 'Eva Brown',
            username: 'eva_brown',
            imageUrl: 'https://i.pravatar.cc/150?img=5',
            monthlyAmount: 160.0,
          ),
        ],
      ),
      SimpleLendingGroup(
        id: 'test_group_2',
        name: 'Startup Funding Pool',
        description: 'Investment group for startup funding',
        status: SimpleGroupStatus.forming,
        baseAmount: 500.0,
        totalMembers: 8,
        currentMembers: 3,
        totalRounds: 8,
        currentRound: 1,
        members: [
          SimpleMember(
            name: 'Frank Miller',
            username: 'frank_m',
            imageUrl: 'https://i.pravatar.cc/150?img=6',
            monthlyAmount: 500.0,
            isAdmin: true,
          ),
          SimpleMember(
            name: 'Grace Lee',
            username: 'grace_lee',
            imageUrl: 'https://i.pravatar.cc/150?img=7',
            monthlyAmount: 500.0,
          ),
          SimpleMember(
            name: 'Henry Chen',
            username: 'henry_c',
            imageUrl: 'https://i.pravatar.cc/150?img=8',
            monthlyAmount: 500.0,
          ),
        ],
      ),
      SimpleLendingGroup(
        id: 'test_group_3',
        name: 'Family Emergency Fund',
        description: 'Emergency fund for family members',
        imageUrl: 'https://picsum.photos/id/238/200/300',
        status: SimpleGroupStatus.completed,
        baseAmount: 300.0,
        totalMembers: 4,
        currentMembers: 4,
        totalRounds: 4,
        currentRound: 4,
        members: [
          SimpleMember(
            name: 'Isabella Garcia',
            username: 'isabella_g',
            imageUrl: 'https://i.pravatar.cc/150?img=9',
            monthlyAmount: 360.0,
            isAdmin: true,
          ),
          SimpleMember(
            name: 'Jack Rodriguez',
            username: 'jack_r',
            imageUrl: 'https://i.pravatar.cc/150?img=10',
            monthlyAmount: 300.0,
          ),
          SimpleMember(
            name: 'Kate Martinez',
            username: 'kate_m',
            imageUrl: 'https://i.pravatar.cc/150?img=11',
            monthlyAmount: 300.0,
          ),
          SimpleMember(
            name: 'Liam Anderson',
            username: 'liam_a',
            imageUrl: 'https://i.pravatar.cc/150?img=12',
            monthlyAmount: 240.0,
          ),
        ],
      ),
    ];
    
    _initialized = true;
  }

  // Get all groups
  List<SimpleLendingGroup> getAllGroups() {
    initialize();
    return List.from(_groups);
  }

  // Add a new group
  void addGroup(SimpleLendingGroup group) {
    initialize();
    _groups.add(group);
  }

  // Reset data
  void resetData() {
    _groups.clear();
    _initialized = false;
    initialize();
  }
}

