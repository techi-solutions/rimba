import 'package:flutter/cupertino.dart';
import 'package:pay_app/services/db/app/contacts.dart';
import 'package:pay_app/state/contacts/contacts.dart';
import 'package:provider/provider.dart';

class AddMemberModal extends StatefulWidget {
  final Function(String, String?) onAdd;

  const AddMemberModal({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<AddMemberModal> {
  final TextEditingController _searchController = TextEditingController();
  ContactsState? _contactsState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadContacts();
      }
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contactsState ??= context.read<ContactsState>();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    if (_contactsState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _contactsState?.clearDbContactsSearch();
      });
    }
    super.dispose();
  }

  Future<void> _loadContacts() async {
    await _contactsState?.fetchDbContacts();
  }

  void _onSearchChanged() {
    _contactsState?.searchDbContacts(_searchController.text);
  }

  void _selectContact(DBContact contact) {
    widget.onAdd(contact.account, contact.name);
    Navigator.of(context).pop();
  }

  void _addManualEntry() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // Only allow account addresses (0x...) for manual entry
      // Usernames must be found via search to get their account address
      if (_isValidEthereumAddress(query)) {
        widget.onAdd(query, null);
        Navigator.of(context).pop();
      }
    }
  }

  bool _isValidEthereumAddress(String address) {
    // Check if it's a valid Ethereum address format
    return address.startsWith('0x') && address.length == 42;
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = context.watch<ContactsState>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Member',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: 'Search by name, username, or address',
              autofocus: true,
              padding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 8),

          // Contact list
          Expanded(
            child: _buildContactList(contactsState),
          ),

          // Add manual entry button (only shown for valid account addresses)
          if (contactsState.dbContactsSearchQuery.isNotEmpty &&
              contactsState.filteredDbContacts.isEmpty &&
              contactsState.remoteSearchResult == null &&
              !contactsState.isSearchingRemote &&
              _isValidEthereumAddress(contactsState.dbContactsSearchQuery))
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _addManualEntry,
                  child: const Text('Add address'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactList(ContactsState contactsState) {
    if (contactsState.isLoadingDbContacts) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    // Show remote contact if found
    if (contactsState.remoteSearchResult != null) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Found user',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          _buildContactItem(contactsState.remoteSearchResult!),
        ],
      );
    }

    // Show searching indicator
    if (contactsState.isSearchingRemote) {
      final query = contactsState.dbContactsSearchQuery;
      final isAddress = query.startsWith('0x');
      final displayQuery = isAddress
          ? '${query.substring(0, 6)}...${query.substring(query.length - 4)}'
          : '@${query.replaceFirst('@', '')}';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(height: 16),
            Text(
              'Searching for $displayQuery...',
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        ),
      );
    }

    if (contactsState.filteredDbContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_2,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              contactsState.dbContactsSearchQuery.isEmpty
                  ? 'No contacts available'
                  : 'No contacts found',
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
              ),
            ),
            if (contactsState.dbContactsSearchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Tap the button below to add manually',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey2,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contactsState.filteredDbContacts.length,
      itemBuilder: (context, index) {
        final contact = contactsState.filteredDbContacts[index];
        return _buildContactItem(contact);
      },
    );
  }

  Widget _buildContactItem(DBContact contact) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _selectContact(contact),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                contact.type == ContactType.place
                    ? CupertinoIcons.building_2_fill
                    : CupertinoIcons.person_fill,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(width: 12),
            // Contact info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${contact.username}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (contact.account.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${contact.account.substring(0, 6)}...${contact.account.substring(contact.account.length - 4)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Arrow icon
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey3,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
