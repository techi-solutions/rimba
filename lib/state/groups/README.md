# Groups State Management

This directory contains the state management for groups CRUD operations in the Rimba app.

## Files

- `groups.dart` - Main state management class for groups operations
- `README.md` - This documentation file

## Features

The `GroupsState` class provides the following CRUD operations:

### Create
- `createGroup()` - Create a new group with name, description, amount, and member accounts
- `addGroupMember()` - Add a member to an existing group

### Read
- `fetchGroups()` - Fetch all groups
- `getGroupById()` - Get a specific group by ID
- `selectGroup()` - Select a group and fetch its members
- `searchGroups()` - Search groups by name or description
- `getGroupMembers()` - Get members of a specific group

### Update
- `updateGroup()` - Update group name, description, or amount
- `removeGroupMember()` - Remove a member from a group

### Delete
- `deleteGroup()` - Delete a group and all its members

## Usage

### 1. Access the state in your widget

```dart
Consumer<GroupsState>(
  builder: (context, groupsState, child) {
    // Use groupsState here
  },
)
```

### 2. Fetch groups

```dart
await groupsState.fetchGroups();
```

### 3. Create a new group

```dart
final newGroup = await groupsState.createGroup(
  name: 'Weekend Trip',
  description: 'Split costs for our weekend getaway',
  amount: '250.00',
  memberAccounts: ['0x1234...', '0x5678...'],
);
```

### 4. Search groups

```dart
await groupsState.searchGroups('weekend');
```

### 5. Select a group and view its members

```dart
await groupsState.selectGroup('group_id');
// Access selectedGroup and currentGroupMembers
```

## State Properties

- `groups` - List of all groups
- `currentGroupMembers` - Members of the currently selected group
- `selectedGroup` - Currently selected group
- `searchQuery` - Current search query
- `isLoading` - Loading state
- `error` - Error message if any

## Mock Service

The groups functionality uses a mock service (`GroupsService`) that provides:
- 5 sample groups with realistic data
- Simulated network delays
- Full CRUD operations
- Member management

## Example UI Components

See `lib/widgets/groups/groups_list.dart` and `lib/screens/groups/screen.dart` for example implementations of the groups UI.
