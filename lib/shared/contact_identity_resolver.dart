import 'package:flutter/foundation.dart';
import 'package:zexano_sms/core/utils/normalization_engine.dart';
import 'package:zexano_sms/features/sms/data/datasources/sms_local_source.dart';

/// Unified contact name resolution.
///
/// **Invariant #3:** This is the SINGLE source of truth for resolving a
/// display name from a phone number or alphanumeric sender ID. Used by:
///   - History (incoming SMS name display)
///   - Conversations (AppBar and list tile name)
///   - IncomingSmsService (enriches new inbound rows)
///
/// **Resolution priority:**
/// ```
/// 1. Contacts table (live, normalized phone match)     ← most accurate
/// 2. Stored contactName in message_history row         ← cached
/// 3. Raw sender ID / phone number                     ← fallback
/// ```
///
/// **Invariant #4:** Live lookup results are persisted to the DB row via
/// [enrichInboundName] so subsequent reads use the cached value, avoiding
/// repeated lookups.
class ContactIdentityResolver {
  final SmsLocalSource _localSource;
  final NormalizationEngine _normalizationEngine;

  ContactIdentityResolver({
    required SmsLocalSource localSource,
    required NormalizationEngine normalizationEngine,
  })  : _localSource = localSource,
        _normalizationEngine = normalizationEngine;

  /// Resolves the display name for a message sender or peer.
  ///
  /// [phoneOrSender] — raw phone number, alphanumeric ID, or `peerId` (e.g. 'sms:+967...', 'sms:6060', 'sms:SABAFON').
  /// [storedName]    — the `contact_name` already stored in the DB row (may be empty).
  ///
  /// Returns the best available display name per the 4-tier priority contract:
  ///   1. Contact name from DB (matching normalizedPhone or phoneNumber)
  ///   2. [storedName] (if non-empty)
  ///   3. Clean Sender ID / Short code (e.g. "6060", "SABAFON")
  ///   4. Raw phone number / identifier fallback
  Future<String> resolveName({
    required String phoneOrSender,
    String? storedName,
  }) async {
    final cleanInput = phoneOrSender.startsWith('sms:')
        ? phoneOrSender.substring(4)
        : phoneOrSender;

    if (cleanInput.isEmpty) {
      return storedName?.isNotEmpty == true ? storedName! : '';
    }

    // Priority 1: Live contact table lookup.
    try {
      final normalized = _normalizationEngine.normalize(cleanInput);
      if (normalized.isNotEmpty) {
        final contact = await _localSource.getContactByAnyPhone(normalized);
        if (contact != null) {
          final name = '${contact.firstName} ${contact.lastName}'.trim();
          if (name.isNotEmpty) return name;
        }
      } else {
        // Alphanumeric Sender ID or short code: check if saved in contacts table
        final contact = await _localSource.getContactByAnyPhone(cleanInput);
        if (contact != null) {
          final name = '${contact.firstName} ${contact.lastName}'.trim();
          if (name.isNotEmpty) return name;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[ContactIdentityResolver] lookup error: $e');
    }

    // Priority 2: Stored name in the DB row.
    if (storedName != null && storedName.trim().isNotEmpty) {
      return storedName.trim();
    }

    // Priority 3 & 4: Clean Sender ID / Short code / raw phone number.
    return cleanInput;
  }

  /// Backfills the contact name for an inbound row that was written with an
  /// empty contact_name (e.g., by the Kotlin native receiver when app was
  /// backgrounded).
  ///
  /// **Invariant #4:** Display-time resolution + DB persistence.
  ///   - If a contact is found: UPDATE the DB row so future reads use the cache.
  ///   - If no contact: leave the row unchanged (phone number shown as fallback).
  Future<void> enrichInboundName({
    required String rowId,
    required String senderPhone,
  }) async {
    final normalized = _normalizationEngine.normalize(senderPhone);
    if (normalized.isEmpty) return; // alphanumeric sender — no contact to find

    try {
      final contact = await _localSource.getContactByAnyPhone(normalized);
      if (contact == null) return;

      final resolvedName = '${contact.firstName} ${contact.lastName}'.trim();
      if (resolvedName.isEmpty) return;

      // Write the resolved name to the DB row so future reads use the cache.
      // This is a fire-and-forget background write — non-fatal if it fails.
      await _localSource.updateInboundContactName(
        rowId: rowId,
        contactName: resolvedName,
        contactId: contact.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ContactIdentityResolver] enrichInboundName error: $e');
      }
    }
  }

  /// Backfills contact names for ALL inbound rows that have an empty
  /// `contact_name`. Runs once on app startup after contacts are loaded.
  ///
  /// **Invariant #4:** This ensures that messages received while the app was
  /// backgrounded (written by Kotlin with `contactName = ""`) get resolved on
  /// next foreground.
  ///
  /// Safe to call multiple times — rows with existing names are skipped by
  /// the WHERE clause in [SmsLocalSource.getInboundRowsWithEmptyName].
  Future<void> backfillInboundNames() async {
    try {
      final emptyNameRows = await _localSource.getInboundRowsWithEmptyName();
      if (emptyNameRows.isEmpty) return;

      if (kDebugMode) {
        debugPrint(
            '[ContactIdentityResolver] backfilling ${emptyNameRows.length} inbound rows');
      }

      for (final row in emptyNameRows) {
        await enrichInboundName(
          rowId: row.id,
          senderPhone: row.targetPhone,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ContactIdentityResolver] backfillInboundNames error: $e');
      }
    }
  }
}
