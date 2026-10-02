import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zexano_sms/core/di/injection_container.dart';
import 'package:zexano_sms/features/contacts/data/handlers/csv_vcf_contacts_handler.dart';
import 'package:zexano_sms/features/contacts/data/handlers/device_contacts_handler.dart';
import 'package:zexano_sms/features/contacts/domain/entities/contact.dart';
import 'package:zexano_sms/features/contacts/domain/value_objects/contact_filter.dart';
import 'package:zexano_sms/features/contacts/presentation/providers/contacts_providers.dart';

/// حالة نتيجة استيراد جهات الاتصال
enum ImportStatus {
  permissionDenied,
  noContacts,
  success,
  onlyDuplicates,
  noFileSelected,
}

/// نتيجة مفصّلة لعملية الاستيراد
class ImportOutcome {
  final ImportStatus status;
  final int imported;
  final int duplicates;

  const ImportOutcome({
    required this.status,
    this.imported = 0,
    this.duplicates = 0,
  });
}

class ContactListNotifier
    extends StateNotifier<AsyncValue<List<Contact>>> {
  final Ref _ref;
  bool _favoritesOnly = false;
  bool get favoritesOnly => _favoritesOnly;

  ContactListNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadContacts();
  }

  void setFavoritesOnly(bool value) {
    if (_favoritesOnly == value) return;
    _favoritesOnly = value;
    final query = _ref.read(searchQueryProvider);
    loadContacts(query: query);
  }

  Future<void> loadContacts({String? query}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(contactsRepositoryProvider);
      if (query != null && query.isNotEmpty) {
        final result = await repo.searchContacts(query);
        final list = result.fold((f) => throw f, (c) => c);
        return _favoritesOnly ? list.where((c) => c.isFavorite).toList() : list;
      }
      final filter = _favoritesOnly ? const ContactFilter(favoritesOnly: true) : null;
      final result = await repo.listContacts(filter: filter);
      return result.fold((f) => throw f, (c) => c);
    });
  }

  Future<void> refresh() async {
    final query = _ref.read(searchQueryProvider);
    await loadContacts(query: query);
  }

  Future<void> toggleFavorite(String id) async {
    final repo = _ref.read(contactsRepositoryProvider);
    final result = await repo.toggleFavorite(id);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (updated) {
        state.whenData((contacts) {
          if (_favoritesOnly && !updated.isFavorite) {
            state = AsyncValue.data(
              contacts.where((c) => c.id != id).toList(),
            );
          } else {
            state = AsyncValue.data(
              contacts.map((c) => c.id == id ? updated : c).toList(),
            );
          }
        });
      },
    );
  }

  Future<void> deleteContact(String id) async {
    final repo = _ref.read(contactsRepositoryProvider);
    final result = await repo.deleteContact(id);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        state.whenData((contacts) {
          state = AsyncValue.data(
            contacts.where((c) => c.id != id).toList(),
          );
        });
      },
    );
  }

  Future<ImportOutcome> importFromDevice() async {
    state = const AsyncValue.loading();
    final handler = sl<DeviceContactsHandler>();

    // ① طلب الإذن
    final permissionGranted = await handler.requestPermission();
    if (!permissionGranted) {
      // استعد الحالة الحالية دون تغيير
      await _reloadContacts();
      return const ImportOutcome(status: ImportStatus.permissionDenied);
    }

    // ② جلب جهات اتصال الجهاز
    final deviceContacts = await handler.getDeviceContacts();
    if (deviceContacts.isEmpty) {
      await _reloadContacts();
      return const ImportOutcome(status: ImportStatus.noContacts);
    }

    // ③ الاستيراد الفعلي
    final repo = _ref.read(contactsRepositoryProvider);
    final importResult = await repo.importDeviceContacts(
      deviceContacts: deviceContacts,
    );

    return importResult.fold(
      (f) {
        state = AsyncValue.error(f, StackTrace.current);
        return const ImportOutcome(status: ImportStatus.noContacts);
      },
      (result) async {
        await _reloadContacts();
        final imported = result.imported.length;
        final duplicates = result.duplicates.length;

        if (imported > 0) {
          return ImportOutcome(
            status: ImportStatus.success,
            imported: imported,
            duplicates: duplicates,
          );
        } else if (duplicates > 0) {
          return ImportOutcome(
            status: ImportStatus.onlyDuplicates,
            duplicates: duplicates,
          );
        } else {
          return const ImportOutcome(status: ImportStatus.noContacts);
        }
      },
    );
  }

  Future<ImportOutcome> importFromFile() async {
    final handler = sl<CsvVcfContactsHandler>();

    final fileContacts = await handler.pickAndParseFile();

    if (fileContacts == null) {
      await _reloadContacts();
      return const ImportOutcome(status: ImportStatus.noFileSelected);
    }

    if (fileContacts.isEmpty) {
      await _reloadContacts();
      return const ImportOutcome(status: ImportStatus.noContacts);
    }

    state = const AsyncValue.loading();

    final repo = _ref.read(contactsRepositoryProvider);
    final importResult = await repo.importDeviceContacts(
      deviceContacts: fileContacts,
    );

    return importResult.fold(
      (f) {
        state = AsyncValue.error(f, StackTrace.current);
        return const ImportOutcome(status: ImportStatus.noContacts);
      },
      (result) async {
        await _reloadContacts();
        final imported = result.imported.length;
        final duplicates = result.duplicates.length;

        if (imported > 0) {
          return ImportOutcome(
            status: ImportStatus.success,
            imported: imported,
            duplicates: duplicates,
          );
        } else if (duplicates > 0) {
          return ImportOutcome(
            status: ImportStatus.onlyDuplicates,
            duplicates: duplicates,
          );
        } else {
          return const ImportOutcome(status: ImportStatus.noContacts);
        }
      },
    );
  }

  Future<void> _reloadContacts() async {
    final repo = _ref.read(contactsRepositoryProvider);
    final listResult = await repo.listContacts();
    state = AsyncValue.data(
      listResult.fold((f) => <Contact>[], (c) => c),
    );
  }
}
