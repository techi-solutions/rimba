import 'package:flutter/cupertino.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/services/contacts/contacts.dart';
import 'package:pay_app/services/db/app/contacts.dart';
import 'package:pay_app/services/db/app/db.dart';
import 'package:pay_app/services/preferences/preferences.dart';
import 'package:pay_app/services/wallet/contracts/profile.dart';
import 'package:pay_app/services/wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

class ContactsState extends ChangeNotifier {
  // instantiate services here
  final PreferencesService _preferences = PreferencesService();
  final ContactsTable _contacts = AppDBService().contacts;
  final ContactsService _contactsService = ContactsService();

  final Config _config;

  // private variables here

  // constructor here
  ContactsState(this._config);

  bool _mounted = true;
  void safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // state variables here
  List<SimpleContact> contacts = [];
  String searchQuery = '';
  SimpleContact? customContact;
  ProfileV1? customContactProfile;
  ProfileV1? customContactProfileByUsername;

  // DB Contacts for group member search
  List<DBContact> dbContacts = [];
  List<DBContact> filteredDbContacts = [];
  bool isLoadingDbContacts = false;
  bool isSearchingRemote = false;
  DBContact? remoteSearchResult;
  String dbContactsSearchQuery = '';

  Future? backgroundFetch;

  // state methods here
  Future<void> fetchContacts() async {
    contacts = await _contactsService.getContacts();
    safeNotifyListeners();
  }

  void clearContacts() {
    contacts = [];
    customContact = null;
    safeNotifyListeners();
  }

  void clearSearch() {
    searchQuery = '';
    customContact = null;
    customContactProfile = null;
    customContactProfileByUsername = null;
    safeNotifyListeners();
  }

  void setSearchQuery(String query) async {
    if (backgroundFetch != null) {
      backgroundFetch!.ignore();
    }

    searchQuery = query;
    customContact = null;
    customContactProfile = null;
    customContactProfileByUsername = null;

    if (query.isEmpty) {
      customContact = null;
      safeNotifyListeners();
      return;
    }

    final isPotentialNumber = query.startsWith('+') ||
        query.startsWith('0') ||
        double.tryParse(query) != null;

    if (isPotentialNumber) {
      try {
        final result = await parse(query);

        customContact = SimpleContact(
          name: 'Unknown number',
          phone: result['e164'],
        );

        backgroundFetch = getContactAddress(
          result['e164'],
          'sms',
        ).then((value) async {
          if (value != null) {
            final contact = await _contacts.getByAccount(value.hexEip55);
            final cachedProfile = contact?.getProfile();
            if (cachedProfile != null) {
              customContactProfile = cachedProfile;
              safeNotifyListeners();
            }

            customContactProfile = await getProfile(
              _config,
              value.hexEip55,
            );

            if (customContactProfile != null) {
              _contacts.upsert(DBContact.fromProfile(customContactProfile!));
            }

            safeNotifyListeners();
          }
        });
        return;
      } catch (e, s) {
        print('error: $e');
        print('stack trace: $s');
        customContact = null;
      }
    }

    if (!isPotentialNumber) {
      try {
        if (_isLikelyEthereumAddress(query)) {
          final address = query.trim();

          final contact = await _contacts.getByAccount(address);
          final cachedProfile = contact?.getProfile();
          if (cachedProfile != null) {
            customContactProfileByUsername = cachedProfile;
            safeNotifyListeners();
          }

          backgroundFetch = getProfile(_config, address).then((result) async {
            if (result != null) {
              customContactProfileByUsername = result;
              await _contacts.upsert(DBContact.fromProfile(result));
              safeNotifyListeners();
            }
          });
        } else {
          final potentialUsername = query.trim().replaceFirst('@', '');

          final contact = await _contacts.getByUsername(potentialUsername);
          final cachedProfile = contact?.getProfile();
          if (cachedProfile != null) {
            customContactProfileByUsername = cachedProfile;
            safeNotifyListeners();
          }

          final result = await getProfileByUsername(
            _config,
            potentialUsername,
          );

          print('result: $result');

          customContactProfileByUsername = result;
        }
      } catch (e, s) {
        print('error: $e');
        print('stack trace: $s');
        customContactProfileByUsername = null;
      }
    }

    safeNotifyListeners();
  }

  Future<ProfileV1?> getContactProfileFromUsername(String query) async {
    try {
      final potentialUsername = query.trim().replaceFirst('@', '');

      final contact = await _contacts.getByUsername(potentialUsername);
      final cachedProfile = contact?.getProfile();
      if (cachedProfile != null) {
        getProfileByUsername(
          _config,
          potentialUsername,
        ).then((result) => {
              if (result != null)
                {
                  _contacts.upsert(DBContact.fromProfile(result)),
                }
            });

        return cachedProfile;
      }

      final result = await getProfileByUsername(
        _config,
        potentialUsername,
      );

      return result;
    } catch (e, s) {
      print('error: $e');
      print('stack trace: $s');
      return null;
    }
  }

  Future<ProfileV1?> getContactProfileFromAddress(String address) async {
    try {
      final contact = await _contacts.getByAccount(address);
      final cachedProfile = contact?.getProfile();
      if (cachedProfile != null) {
        getProfile(
          _config,
          address,
        ).then((result) => {
              if (result != null)
                {
                  _contacts.upsert(DBContact.fromProfile(result)),
                }
            });

        return cachedProfile;
      }

      final result = await getProfile(
        _config,
        address,
      );

      return result;
    } catch (e, s) {
      print('error: $e');
      print('stack trace: $s');
      return null;
    }
  }

  Future<EthereumAddress?> getContactAddress(
    String source,
    String type,
  ) async {
    try {
      final result = await parse(source);
      final parsedNumber = result['e164'];
      if (parsedNumber == null) {
        return null;
      }

      return await getTwoFAAddress(
        _preferences,
        _config,
        parsedNumber,
        type,
      );
    } catch (e, s) {
      print('error: $e');
      print('stack trace: $s');
    }

    return null;
  }

  /// Fetch all DB contacts (for member selection modals)
  Future<void> fetchDbContacts() async {
    try {
      isLoadingDbContacts = true;
      safeNotifyListeners();

      final contacts = await _contacts.getAll();
      dbContacts = contacts;
      filteredDbContacts = contacts;
    } catch (e, s) {
      debugPrint('Error fetching DB contacts: $e');
      debugPrint('Stack trace: $s');
    } finally {
      isLoadingDbContacts = false;
      safeNotifyListeners();
    }
  }

  /// Search DB contacts by query (name, username, or account)
  void searchDbContacts(String query) async {
    dbContactsSearchQuery = query.toLowerCase().trim();
    remoteSearchResult = null;

    if (dbContactsSearchQuery.isEmpty) {
      filteredDbContacts = dbContacts;
      safeNotifyListeners();
      return;
    }

    try {
      filteredDbContacts = await _contacts.search(dbContactsSearchQuery);
    } catch (e, s) {
      debugPrint('Error searching contacts: $e');
      debugPrint('Stack trace: $s');
      filteredDbContacts = dbContacts.where((contact) {
        final accountMatch =
            contact.account.toLowerCase().contains(dbContactsSearchQuery);
        final usernameMatch =
            contact.username.toLowerCase().contains(dbContactsSearchQuery);
        final nameMatch =
            contact.name.toLowerCase().contains(dbContactsSearchQuery);
        return accountMatch || usernameMatch || nameMatch;
      }).toList();
    }

    safeNotifyListeners();

    if (filteredDbContacts.isEmpty) {
      if (_isLikelyEthereumAddress(dbContactsSearchQuery)) {
        searchRemoteAddress(dbContactsSearchQuery);
      } else if (_isLikelyUsername(dbContactsSearchQuery)) {
        searchRemoteUsername(dbContactsSearchQuery);
      }
    }
  }

  /// Check if query looks like a username (not an address)
  bool _isLikelyUsername(String query) {
    final trimmed = query.replaceFirst('@', '');
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('0x') &&
        trimmed.length < 42; // Ethereum addresses are 42 chars with 0x
  }

  /// Check if query looks like an Ethereum address
  bool _isLikelyEthereumAddress(String query) {
    final trimmed = query.trim();
    return trimmed.startsWith('0x') &&
        (trimmed.length == 42 || trimmed.length >= 10);
  }

  /// Search for a username on blockchain/IPFS
  Future<void> searchRemoteUsername(String query) async {
    try {
      isSearchingRemote = true;
      safeNotifyListeners();

      final username = query.replaceFirst('@', '');
      final profile = await getProfileByUsername(_config, username);

      if (profile != null) {
        final remoteContact = DBContact.fromProfile(profile);

        // Cache it in local database
        await _contacts.upsert(remoteContact);

        remoteSearchResult = remoteContact;
      }
    } catch (e, s) {
      debugPrint('Error searching remote username: $e');
      debugPrint('Stack trace: $s');
    } finally {
      isSearchingRemote = false;
      safeNotifyListeners();
    }
  }

  /// Search for an address on blockchain/IPFS
  Future<void> searchRemoteAddress(String query) async {
    try {
      isSearchingRemote = true;
      safeNotifyListeners();

      final address = query.trim();

      // Validate it's a valid Ethereum address format
      if (!address.startsWith('0x') || address.length != 42) {
        debugPrint('Invalid Ethereum address format: $address');
        return;
      }

      // Try to get the profile from the blockchain
      final profile = await getProfile(_config, address);

      if (profile != null) {
        final remoteContact = DBContact.fromProfile(profile);

        // Cache it in local database
        await _contacts.upsert(remoteContact);

        remoteSearchResult = remoteContact;
      }
    } catch (e, s) {
      debugPrint('Error searching remote address: $e');
      debugPrint('Stack trace: $s');
    } finally {
      isSearchingRemote = false;
      safeNotifyListeners();
    }
  }

  /// Clear DB contacts search
  void clearDbContactsSearch() {
    dbContactsSearchQuery = '';
    filteredDbContacts = dbContacts;
    remoteSearchResult = null;
    isSearchingRemote = false;
    safeNotifyListeners();
  }
}
