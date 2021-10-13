import 'dart:async';
import 'dart:convert';

import 'package:aes_ecb_pkcs5_flutter/aes_ecb_pkcs5_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:polkawallet_sdk/storage/localStorage.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/index.dart';
import 'package:polkawallet_sdk/utils/localStorage.dart';

/// A [Keyring] instance maintains the local storage
/// of key-pairs for users.
/// We need to pass the storage instance to [WalletSDK]'s
/// keyring api for account management.
class Keyring {
  late KeyringPrivateStore store;

  int? get ss58 => store.ss58;
  int? setSS58(int? ss58) {
    store.ss58 = ss58;
    return ss58;
  }

  KeyPairData get current {
    final list = allAccounts;
    if (list.length > 0) {
      final i = list.indexWhere((e) => e.pubKey == store.currentPubKey);
      return i >= 0 ? list[i] : KeyPairData();
    }
    return KeyPairData();
  }

  void setCurrent(KeyPairData acc) {
    print('====== setCurrent 设置当前账户 ======');
    print(acc);
    store.setCurrentPubKey(acc.pubKey);
    store.setCurrentQSPubKey(acc.qsPubKey ?? '');
  }

  List<KeyPairData> get keyPairs {
    return store.list.map((e) => KeyPairData.fromJson(e)).toList();
  }

  List<KeyPairData> get externals {
    return store.externals.map((e) => KeyPairData.fromJson(e)).toList();
  }

  List<KeyPairData> get contacts {
    return store.contacts.map((e) => KeyPairData.fromJson(e)).toList();
  }

  List<KeyPairData> get allAccounts {
    final res = keyPairs;
    res.addAll(externals);
    return res;
  }

  List<KeyPairData> get allWithContacts {
    final res = keyPairs;
    res.addAll(contacts);
    return res;
  }

  List<KeyPairData> get optionals {
    final res = allAccounts;
    res.removeWhere((e) => e.pubKey == current.pubKey);
    return res;
  }

  Future<void> init(List<int> ss58List) async {
    store = KeyringPrivateStore(ss58List);
    await store.init();
  }
}

class KeyringPrivateStore {
  KeyringPrivateStore(this.ss58List);
  final KeyringStorage _storage = KeyringStorage();
  final LocalStorage _storageOld = LocalStorage();
  final List<int> ss58List;

  Map<String, Map> _pubKeyAddressMap = {};
  Map<String, String> _iconsMap = {};
  Map<String, Map> _indicesMap = {};

  int? ss58 = 0;

  String? get currentPubKey => _storage.currentPubKey.val;
  String? get currentQSPubKey => _storage.currentQSPubKey.val;

  void setCurrentPubKey(String? pubKey) {
    _storage.currentPubKey.val = pubKey;
  }

  void setCurrentQSPubKey(String? qsPubKey) {
    _storage.currentQSPubKey.val = qsPubKey;
  }

  List get list {
    return _formatAccount(_storage.keyPairs.val.toList());
  }

  List get externals {
    final ls = _storage.contacts.val.toList();
    ls.retainWhere((e) => e['observation'] ?? false);
    return _formatAccount(ls);
  }

  List get contacts {
    return _formatAccount(_storage.contacts.val.toList());
  }

  Map<String, Map> get pubKeyAddressMap {
    return _pubKeyAddressMap;
  }

  List _formatAccount(List ls) {
    ls.forEach((e) {
      final networkSS58 = ss58.toString();
      if (_pubKeyAddressMap[networkSS58] != null &&
          _pubKeyAddressMap[networkSS58]![e['pubKey']] != null) {
        e['address'] = _pubKeyAddressMap[networkSS58]![e['pubKey']];
      }
      e['icon'] = _iconsMap[e['pubKey']];
      e['indexInfo'] = _indicesMap[e['address']];
    });
    return ls;
  }

  /// the [GetStorage] package needs to be initiated before use.
  Future<void> init() async {
    print('====== keyring: init ======');
    await GetStorage.init(sdk_storage_key); // ^^^^^^
    await _loadKeyPairsFromStorage();
  }

  /// load keyPairs form local storage to memory.
  Future<void> _loadKeyPairsFromStorage() async {
    print('====== _loadKeyPairsFromStorage ======');
    final ls = await _storageOld.getAccountList();
    print(jsonEncode(ls));
    if (ls.length > 0) {
      ls.retainWhere((e) {
        // delete all storageOld data
        _storageOld.removeAccount(e['pubKey']);
        if (e['mnemonic'] != null || e['rawSeed'] != null) {
          e.remove('mnemonic');
          e.remove('rawSeed');
        }

        // retain accounts from storageOld
        final i = _storage.keyPairs.val.indexWhere((pair) {
          return pair['pubKey'] == e['pubKey'];
        });
        return i < 0;
      });
      final List pairs = _storage.keyPairs.val.toList();
      print(jsonEncode(pairs));
      pairs.addAll(ls);
      _storage.keyPairs.val = pairs;

      // load current account pubKey ^^^^^^
      final curr = await _storageOld.getCurrentAccount();
      print('====== keyring: curr ======');
      print(curr);
      if (curr != null && curr.isNotEmpty) {
        setCurrentPubKey(curr);
        _storageOld.setCurrentAccount('');
      }

      // and move all encrypted seeds to new storage
      _migrateSeeds();
    }
  }

  void updatePubKeyAddressMap(Map<String, Map> data) {
    _pubKeyAddressMap = data;
  }

  void updateIconsMap(Map<String, String> data) {
    _iconsMap.addAll(data);
  }

  void updateIndicesMap(Map<String, Map> data) {
    _indicesMap = data;
  }

  Future<void> addAccount(Map acc) async {
    final pairs = _storage.keyPairs.val.toList(); // ^^^^^^
    // remove duplicated account and add a new one
    print('====== storage::addAccount ===========');
    print(acc);
    pairs.retainWhere((e) => e['pubKey'] != acc['pubKey']);
    pairs.add(acc);
    _storage.keyPairs.val = pairs;

    setCurrentPubKey(acc['pubKey']);
    setCurrentQSPubKey(acc['qsPubKey']);
  }

  Future<void> addContact(Map acc) async {
    print('====== storage::addContact ===========');
    print(acc);
    final ls = _storage.contacts.val.toList();
    ls.add(acc);
    _storage.contacts.val = ls;

    if (acc['observation'] ?? false) {
      setCurrentPubKey(acc['pubKey']);
      setCurrentQSPubKey(acc['qsPubKey']);
    }
  }

  Future<void> updateAccount(Map acc, {bool isExternal: false}) async {
    print('====== storage::updateAccount ===========');
    print(acc);
    if (isExternal) {
      updateContact(acc);
    } else {
      _updateKeyPair(acc);
    }
  }

  Future<void> _updateKeyPair(Map acc) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['pubKey'] == acc['pubKey']);
    pairs.add(acc);
    _storage.keyPairs.val = pairs;
  }

  Future<void> updateContact(Map acc) async {
    final ls = _storage.contacts.val.toList();
    ls.removeWhere((e) => e['pubKey'] == acc['pubKey']);
    ls.add(acc);
    _storage.contacts.val = ls;
  }

  Future<void> deleteAccount(String? pubKey) async {
    _deleteKeyPair(pubKey);

    final mnemonics = Map.of(_storage.encryptedMnemonics.val);
    mnemonics.removeWhere((key, _) => key == pubKey);
    _storage.encryptedMnemonics.val = mnemonics;

    final seeds = Map.of(_storage.encryptedRawSeeds.val);
    seeds.removeWhere((key, _) => key == pubKey);
    _storage.encryptedRawSeeds.val = seeds;
  }

  Future<void> deleteQSAccount(String? pubKey) async {
    _deleteKeyPair(pubKey);
    final qsMnemonic = Map.of(_storage.encryptedQSMnemonics.val);
    qsMnemonic.removeWhere((key, _) => key == pubKey);
    _storage.encryptedQSMnemonics.val = qsMnemonic;
  }

  Future<void> _deleteKeyPair(String? pubKey) async {
    final List pairs = _storage.keyPairs.val.toList();
    pairs.removeWhere((e) => e['pubKey'] == pubKey);
    _storage.keyPairs.val = pairs;

    if (pairs.length > 0) {
      setCurrentPubKey(pairs[0]['pubKey']);
      setCurrentQSPubKey(pairs[0]['qsPubKey']);
    } else if (externals.length > 0) {
      setCurrentPubKey(externals[0]['pubKey']);
      setCurrentQSPubKey(externals[0]['qsPubKey']);
    } else {
      setCurrentPubKey('');
      setCurrentQSPubKey('');
    }
  }

  Future<void> deleteContact(String pubKey) async {
    final ls = _storage.contacts.val.toList();
    ls.removeWhere((e) => e['pubKey'] == pubKey);
    _storage.contacts.val = ls;
  }

  Future<void> encryptSeedAndSave(
      String? pubKey, seed, seedType, password) async {
    final String key = Encrypt.passwordToEncryptKey(password);
    final String encrypted = await FlutterAesEcbPkcs5.encryptString(seed, key);

    // read old seed from storage-old
    final Map stored = await (_storageOld.getSeeds(seedType)
        as FutureOr<Map<dynamic, dynamic>>);
    stored[pubKey] = encrypted;

    // and save to new storage
    if (seedType == KeyType.mnemonic.toString().split('.')[1]) {
      final mnemonics = Map.from(_storage.encryptedMnemonics.val);
      mnemonics.addAll(stored);
      _storage.encryptedMnemonics.val = mnemonics;
      return;
    }
    if (seedType == KeyType.rawSeed.toString().split('.')[1]) {
      final seeds = Map.from(_storage.encryptedRawSeeds.val);
      seeds.addAll(stored);
      _storage.encryptedRawSeeds.val = seeds;
    }
  }

  // $$$$$$
  Future<void> encryptQSMnemonicAndSave(
      String? pubKey, qsMnemonic, password) async {
    final String key = Encrypt.passwordToEncryptKey(password);
    final String qsEncrypted =
        await FlutterAesEcbPkcs5.encryptString(qsMnemonic, key);

    // Read old qsMnemonic from storage-old
    final Map qsStored = await (_storageOld.getSeeds('qsmnemonic')
        as FutureOr<Map<dynamic, dynamic>>);
    qsStored[pubKey] = qsEncrypted;

    // save qsMnemonic to new storage
    qsMnemonic = Map.from(_storage.encryptedQSMnemonics.val);
    qsMnemonic.addAll(qsStored);
    _storage.encryptedQSMnemonics.val = qsMnemonic;
  }

  // $$$$$$
  Future<void> updateEncryptedSeed(String? pubKey, passOld, passNew) async {
    final seed = await (getDecryptedSeed(pubKey, passOld)
        as FutureOr<Map<String, dynamic>>);
    encryptSeedAndSave(pubKey, seed['seed'], seed['type'], passNew);
  }

  // $$$$$$
  Future<void> updateEncryptedQSMnemonic(
      String? qsPubKey, passOld, passNew) async {
    final seed = await (getDecryptedQSSeed(qsPubKey, passOld)
        as FutureOr<Map<dynamic, dynamic>>);
    encryptQSMnemonicAndSave(qsPubKey, seed['seed'], passNew);
  }

  Future<Map<String, dynamic>?> getDecryptedSeed(
      String? pubKey, password) async {
    final key = Encrypt.passwordToEncryptKey(password);
    final mnemonic = _storage.encryptedMnemonics.val[pubKey];
    if (mnemonic != null) {
      final res = {'type': KeyType.mnemonic.toString().split('.')[1]};
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(mnemonic, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    final rawSeed = _storage.encryptedRawSeeds.val[pubKey];
    if (rawSeed != null) {
      final res = {'type': KeyType.rawSeed.toString().split('.')[1]};
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(rawSeed, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getDecryptedQSSeed(
      String? qsPubKey, password) async {
    final key = Encrypt.passwordToEncryptKey(password);
    final mnemonic = _storage.encryptedQSMnemonics.val[qsPubKey];
    if (mnemonic != null) {
      final res = {'type': 'qsMnemonic'}; // ^^^^^^
      try {
        res['seed'] = await FlutterAesEcbPkcs5.decryptString(mnemonic, key);
      } catch (err) {
        print(err);
      }
      return res;
    }
    return null;
  }

  Future<bool> checkSeedExist(KeyType keyType, String pubKey) async {
    switch (keyType) {
      case KeyType.mnemonic:
        return _storage.encryptedMnemonics.val[pubKey] != null;
      case KeyType.rawSeed:
        return _storage.encryptedRawSeeds.val[pubKey] != null;
      default:
        return false;
    }
  }

  Future<void> _migrateSeeds() async {
    final res = await Future.wait([
      _storageOld.getSeeds('mnemonic'),
      _storageOld.getSeeds('rawSeed'),
      _storageOld.getSeeds('qsmnemonic'),
    ]);
    if (res[0]!.keys.length > 0) {
      final mnemonics = Map.of(_storage.encryptedMnemonics.val);
      mnemonics.addAll(res[0]!);
      _storage.encryptedMnemonics.val = mnemonics;
      _storageOld.setSeeds('mnemonic', {});
    }
    if (res[1]!.keys.length > 0) {
      final seeds = Map.of(_storage.encryptedRawSeeds.val);
      seeds.addAll(res[1]!);
      _storage.encryptedRawSeeds.val = seeds;
      _storageOld.setSeeds('rawSeed', {});
    }

    if (res[2]!.keys.length > 0) {
      final qsMnemonic = Map.of(_storage.encryptedQSMnemonics.val);
      qsMnemonic.addAll(res[2]!);
      _storage.encryptedQSMnemonics.val = qsMnemonic;
      _storageOld.setSeeds('qsmnemonic', {});
    }
  }
}
