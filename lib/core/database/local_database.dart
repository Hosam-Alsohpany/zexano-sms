import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

class Tenants extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get accountType => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get phoneNumber => text()();
  TextColumn get normalizedPhone => text()();

  // Issue #2: operatorName is nullable — 'Unknown' was semantically dishonest.
  // Null means "operator could not be determined"; the domain layer maps null → ''.
  TextColumn get operatorName => text().nullable()();

  // Issue #1: notes is nullable — avoids forcing empty-string storage for
  // optional free-text. The domain layer maps null → '' for display safety.
  TextColumn get notes => text().nullable()();

  IntColumn get isFavorite => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {normalizedPhone},
  ];
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get name => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// Issue #4: cascade delete on contactId → when a Contact is deleted, all its
// ContactTags rows are deleted automatically by SQLite (PRAGMA foreign_keys=ON).
class ContactTags extends Table {
  TextColumn get contactId =>
      text().references(Contacts, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {contactId, tagId};
}

class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get name => text()();
  TextColumn get description => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// Issue #4: cascade delete on both FKs —
//   groupId:   when a Group is deleted, all its GroupMembers are removed.
//   contactId: when a Contact is deleted, all its GroupMembers are removed.
class GroupMembers extends Table {
  TextColumn get groupId =>
      text().references(Groups, #id, onDelete: KeyAction.cascade)();
  TextColumn get contactId =>
      text().references(Contacts, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {groupId, contactId};
}

class MessageTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get title => text()();
  TextColumn get bodyContent => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class MessageHistory extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get batchId => text()();
  TextColumn get contactName => text()();
  TextColumn get contactId => text().nullable()();
  TextColumn get targetPhone => text()();
  TextColumn get messageBody => text()();
  TextColumn get channelType => text()();
  TextColumn get executionStatus => text()();
  IntColumn get timestamp => integer()();
  IntColumn get sentAt => integer().nullable()();

  // v5 additions ─────────────────────────────────────────────────────────────
  /// Open TEXT field — valid values: manual | contact | group | import | api …
  /// Stored as plain text so new source types never require a schema migration.
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();

  /// Outbound messages sent by Zexano; inbound messages received from the user.
  TextColumn get direction => text().withDefault(const Constant('outbound'))();

  /// Non-null when the message was sent as part of a group bulk send.
  TextColumn get groupId => text().nullable()();

  /// Epoch-seconds timestamp of when an inbound SMS was received.
  IntColumn get receivedAt => integer().nullable()();
  // ─────────────────────────────────────────────────────────────────────────

  // v6 additions ─────────────────────────────────────────────────────────────
  TextColumn get peerId => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Set<Column> get primaryKey => {id};
}

class Conversations extends Table {
  TextColumn get peerId => text()();
  TextColumn get lastMessageId => text().nullable()();
  IntColumn get lastMessageTimestamp => integer().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  TextColumn get draft => text().nullable()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {peerId};
}

class AssistedSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get messageBody => text()();
  IntColumn get totalRecipients => integer()();
  IntColumn get completedRecipients => integer()();
  IntColumn get failedRecipients => integer()();
  IntColumn get currentIndex => integer()();
  TextColumn get status => text()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {sessionId};
}

// Issue #5: cascade delete on sessionId → deleting an AssistedSession removes
// all its StagedRecipients, preventing orphan rows.
class StagedRecipients extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(AssistedSessions, #sessionId, onDelete: KeyAction.cascade)();
  TextColumn get phoneNumber => text()();
  TextColumn get contactName => text()();
  TextColumn get contactId => text().nullable()();
  TextColumn get status => text()();
  IntColumn get launchSuccess => integer()();
  TextColumn get failureReason => text().nullable()();
  IntColumn get attemptedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Issue #3: UNIQUE(tenantId) prevents multiple preference rows per tenant.
// One tenant may only have one active WhatsApp preference at a time.
class WhatsAppPreference extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text().references(Tenants, #id)();
  TextColumn get packageName => text()();
  TextColumn get appName => text()();
  IntColumn get isSet => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {tenantId},
  ];
}

@DriftDatabase(
  tables: [
    Tenants,
    Contacts,
    Tags,
    ContactTags,
    Groups,
    GroupMembers,
    MessageTemplates,
    MessageHistory,
    AssistedSessions,
    StagedRecipients,
    WhatsAppPreference,
    Conversations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Enable foreign-key enforcement for new databases.
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Enable foreign-key enforcement for all upgrades.
      await customStatement('PRAGMA foreign_keys = ON');

      if (from < 2) {
        await m.addColumn(messageHistory, messageHistory.batchId);
        await m.addColumn(messageHistory, messageHistory.contactId);
        await m.addColumn(messageHistory, messageHistory.sentAt);
      }
      if (from < 3) {
        await m.createTable(assistedSessions);
        await m.createTable(stagedRecipients);
        await m.createTable(whatsAppPreference);
      }
      if (from < 5) {
        // v5: add sourceType, direction, groupId, receivedAt to MessageHistory.
        // addColumn is safe for nullable columns or columns with a DEFAULT.
        await m.addColumn(messageHistory, messageHistory.sourceType);
        await m.addColumn(messageHistory, messageHistory.direction);
        await m.addColumn(messageHistory, messageHistory.groupId);
        await m.addColumn(messageHistory, messageHistory.receivedAt);
      }
      if (from < 4) {
        // Issue #1: make notes nullable.
        // SQLite does not support ALTER COLUMN. We add a new nullable column
        // and copy data, then drop the old column via table recreation.
        // Drift provides recreateAllViews() + customStatement for this.
        // For the Contacts table we use a safe addColumn approach:
        //   - The old column was NOT NULL with existing non-null data.
        //   - We rename the old table, create the new one, copy data, drop old.
        await _migrateContactsTableV4(m);

        // Issue #3: add UNIQUE(tenantId) to WhatsAppPreference.
        // SQLite does not support ADD CONSTRAINT on existing tables.
        // Recreate the table with the new unique key.
        await _migrateWhatsAppPreferenceTableV4(m);

        // Issues #4 & #5: recreate ContactTags, GroupMembers, StagedRecipients
        // with ON DELETE CASCADE foreign keys.
        await _migrateJunctionTablesV4(m);
      }
      if (from < 6) {
        await m.addColumn(messageHistory, messageHistory.peerId);
        await m.addColumn(messageHistory, messageHistory.isRead);
        await m.createTable(conversations);
        
        await _createConversationsTriggers(m);
      }
    },
    beforeOpen: (details) async {
      // Enforce FK constraints on every connection open.
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated) {
        await _seedDefaultTenant();
      }

      // Triggers: DROP + CREATE on every open to guarantee latest Allowlist logic.
      // Cost: ~2ms on SQLite — acceptable for a development-phase app.
      // Production upgrade path: move to a v7 migration when schema version bumps.
      await _recreateConversationTriggers();

      // Indexes: IF NOT EXISTS — nearly free after first creation (~0ms).
      await _ensureIndexes();
    },
  );

  // ── Trigger management ──────────────────────────────────────────────────────

  /// Called from [MigrationStrategy.onUpgrade] (has Migrator context).
  Future<void> _createConversationsTriggers(Migrator m) async {
    for (final stmt in _getTriggerStatements()) {
      await m.issueCustomQuery(stmt);
    }
  }

  /// Called from [beforeOpen] — drops and recreates to update trigger logic.
  Future<void> _recreateConversationTriggers() async {
    await customStatement('DROP TRIGGER IF EXISTS trg_mh_after_insert');
    await customStatement('DROP TRIGGER IF EXISTS trg_mh_after_update');
    await customStatement('DROP TRIGGER IF EXISTS trg_mh_after_delete');
    await _createConversationsTriggersRaw(this);
  }

  Future<void> _createConversationsTriggersRaw(AppDatabase db) async {
    for (final stmt in _getTriggerStatements()) {
      await db.customStatement(stmt);
    }
  }

  /// Returns the canonical trigger definitions.
  /// Allowlist: source_type IN ('manual','contact','group','campaign','inbound') with valid peer_id create/update Conversations.
  /// Tiebreaker: (timestamp, id) DESC — prevents non-determinism on equal timestamps.
  List<String> _getTriggerStatements() {
    return [
      '''
      CREATE TRIGGER trg_mh_after_insert
      AFTER INSERT ON message_history
      FOR EACH ROW
      WHEN NEW.peer_id IS NOT NULL
        AND NEW.source_type IN ('manual', 'contact', 'group', 'campaign', 'inbound')
      BEGIN
        INSERT INTO conversations (
          peer_id, last_message_id, last_message_timestamp,
          unread_count, draft, is_pinned, is_muted, updated_at
        ) VALUES (
          NEW.peer_id, NEW.id, NEW.timestamp,
          CASE WHEN NEW.direction = 'inbound' AND NEW.is_read = 0 THEN 1 ELSE 0 END,
          NULL, 0, 0, strftime('%s', 'now')
        )
        ON CONFLICT(peer_id) DO UPDATE SET
          last_message_id = CASE
            WHEN NEW.timestamp > last_message_timestamp
              OR (NEW.timestamp = last_message_timestamp AND NEW.id > last_message_id)
            THEN NEW.id ELSE last_message_id END,
          last_message_timestamp = CASE
            WHEN NEW.timestamp > last_message_timestamp
              OR (NEW.timestamp = last_message_timestamp AND NEW.id > last_message_id)
            THEN NEW.timestamp ELSE last_message_timestamp END,
          unread_count = unread_count +
            CASE WHEN NEW.direction = 'inbound' AND NEW.is_read = 0 THEN 1 ELSE 0 END,
          updated_at = strftime('%s', 'now');
      END;
      ''',
      '''
      CREATE TRIGGER trg_mh_after_update
      AFTER UPDATE OF is_read, execution_status ON message_history
      FOR EACH ROW
      WHEN NEW.peer_id IS NOT NULL
      BEGIN
        UPDATE conversations
        SET unread_count = CASE
              WHEN OLD.is_read = 0 AND NEW.is_read = 1 AND NEW.direction = 'inbound'
              THEN MAX(0, unread_count - 1) ELSE unread_count END,
            updated_at = strftime('%s', 'now')
        WHERE peer_id = NEW.peer_id;
      END;
      ''',
      '''
      CREATE TRIGGER trg_mh_after_delete
      AFTER DELETE ON message_history
      FOR EACH ROW
      WHEN OLD.peer_id IS NOT NULL
      BEGIN
        UPDATE conversations
        SET last_message_id = (
              SELECT id FROM message_history
              WHERE peer_id = OLD.peer_id
              ORDER BY timestamp DESC, id DESC LIMIT 1),
            last_message_timestamp = (
              SELECT timestamp FROM message_history
              WHERE peer_id = OLD.peer_id
              ORDER BY timestamp DESC, id DESC LIMIT 1),
            unread_count = MAX(0, unread_count -
              CASE WHEN OLD.direction = 'inbound' AND OLD.is_read = 0 THEN 1 ELSE 0 END),
            updated_at = strftime('%s', 'now')
        WHERE peer_id = OLD.peer_id;

        DELETE FROM conversations WHERE peer_id = OLD.peer_id AND last_message_id IS NULL;
      END;
      '''
    ];
  }

  // ── Indexes ───────────────────────────────────────────────────────────────

  /// Creates all performance indexes. Safe to call on every open — IF NOT EXISTS.
  Future<void> _ensureIndexes() async {
    // peer_id: watchConversation(peerId) = WHERE peer_id = ? — full scan without
    await customStatement('CREATE INDEX IF NOT EXISTS idx_mh_peer_id ON message_history(peer_id)');
    // batch_id: getSmsBatchRows() / deleteSmsBatch() — critical for History
    await customStatement('CREATE INDEX IF NOT EXISTS idx_mh_batch_id ON message_history(batch_id)');
    // (timestamp DESC, id DESC): ORDER BY used in triggers + watchConversations
    await customStatement('CREATE INDEX IF NOT EXISTS idx_mh_ts_id ON message_history(timestamp DESC, id DESC)');
    // direction: WHERE direction = \'outbound\' filter in History
    await customStatement('CREATE INDEX IF NOT EXISTS idx_mh_direction ON message_history(direction)');
    // is_read: markAsRead() — WHERE is_read = 0 AND direction = \'inbound\'
    await customStatement('CREATE INDEX IF NOT EXISTS idx_mh_is_read ON message_history(is_read)');
    // conversations timestamp: ORDER BY last_message_timestamp DESC in Inbox
    await customStatement('CREATE INDEX IF NOT EXISTS idx_conv_ts ON conversations(last_message_timestamp DESC)');
  }

  // ── Backfill ──────────────────────────────────────────────────────────────

  /// Rebuilds [conversations] from existing [message_history] rows.
  ///
  /// Must be called once only — the caller (DI/startup) is responsible for
  /// ensuring this via a SharedPreferences flag ('conv_backfill_done').
  ///
  /// Safe to call multiple times — INSERT OR IGNORE prevents duplicates.
  /// Rows with source_type IN ('manual','contact','group','campaign','inbound') are included
  /// (same Allowlist as the trigger).
  Future<void> backfillConversationsFromHistory() async {
    await customStatement('''
      INSERT OR IGNORE INTO conversations (
        peer_id, last_message_id, last_message_timestamp,
        unread_count, is_pinned, is_muted, updated_at
      )
      SELECT
        peer_id,
        (SELECT id FROM message_history mh2
         WHERE mh2.peer_id = mh.peer_id
         ORDER BY timestamp DESC, id DESC LIMIT 1),
        MAX(timestamp),
        SUM(CASE WHEN direction = 'inbound' AND is_read = 0 THEN 1 ELSE 0 END),
        0, 0, strftime('%s', 'now')
      FROM message_history mh
      WHERE peer_id IS NOT NULL
        AND source_type IN ('manual', 'contact', 'group', 'campaign', 'inbound')
      GROUP BY peer_id
    ''');
  }

  // ── V4 migration helpers ──────────────────────────────────────────────────

  /// Recreates the Contacts table with nullable notes and nullable operatorName.
  Future<void> _migrateContactsTableV4(Migrator m) async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS contacts_v4_new (
        id TEXT NOT NULL,
        tenantId TEXT NOT NULL REFERENCES tenants(id),
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        normalizedPhone TEXT NOT NULL UNIQUE,
        operatorName TEXT,
        notes TEXT,
        isFavorite INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        PRIMARY KEY (id)
      )
    ''');

    await customStatement('''
      INSERT INTO contacts_v4_new
        (id, tenantId, firstName, lastName, phoneNumber, normalizedPhone,
         operatorName, notes, isFavorite, createdAt)
      SELECT
        id, tenantId, firstName, lastName, phoneNumber, normalizedPhone,
        CASE WHEN operatorName = '' OR operatorName = 'Unknown'
             THEN NULL ELSE operatorName END,
        CASE WHEN notes = '' THEN NULL ELSE notes END,
        isFavorite, createdAt
      FROM contacts
    ''');

    await customStatement('DROP TABLE contacts');
    await customStatement('ALTER TABLE contacts_v4_new RENAME TO contacts');
  }

  /// Recreates WhatsAppPreference with UNIQUE(tenantId).
  Future<void> _migrateWhatsAppPreferenceTableV4(Migrator m) async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS whats_app_preference_v4_new (
        id TEXT NOT NULL,
        tenantId TEXT NOT NULL REFERENCES tenants(id) UNIQUE,
        packageName TEXT NOT NULL,
        appName TEXT NOT NULL,
        isSet INTEGER NOT NULL,
        PRIMARY KEY (id)
      )
    ''');

    // Keep only the most-recently-inserted row per tenant (by rowid).
    await customStatement('''
      INSERT OR IGNORE INTO whats_app_preference_v4_new
        (id, tenantId, packageName, appName, isSet)
      SELECT id, tenantId, packageName, appName, isSet
      FROM whats_app_preference
      WHERE rowid IN (
        SELECT MAX(rowid) FROM whats_app_preference GROUP BY tenantId
      )
    ''');

    await customStatement('DROP TABLE whats_app_preference');
    await customStatement(
        'ALTER TABLE whats_app_preference_v4_new RENAME TO whats_app_preference');
  }

  /// Recreates ContactTags, GroupMembers, StagedRecipients with CASCADE FK.
  Future<void> _migrateJunctionTablesV4(Migrator m) async {
    // ── ContactTags ────────────────────────────────────────────────────────
    await customStatement('''
      CREATE TABLE IF NOT EXISTS contact_tags_v4_new (
        contactId TEXT NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
        tagId     TEXT NOT NULL REFERENCES tags(id),
        PRIMARY KEY (contactId, tagId)
      )
    ''');
    await customStatement('''
      INSERT OR IGNORE INTO contact_tags_v4_new (contactId, tagId)
      SELECT contactId, tagId FROM contact_tags
    ''');
    await customStatement('DROP TABLE contact_tags');
    await customStatement(
        'ALTER TABLE contact_tags_v4_new RENAME TO contact_tags');

    // ── GroupMembers ───────────────────────────────────────────────────────
    await customStatement('''
      CREATE TABLE IF NOT EXISTS group_members_v4_new (
        groupId   TEXT NOT NULL REFERENCES groups(id)   ON DELETE CASCADE,
        contactId TEXT NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
        PRIMARY KEY (groupId, contactId)
      )
    ''');
    await customStatement('''
      INSERT OR IGNORE INTO group_members_v4_new (groupId, contactId)
      SELECT groupId, contactId FROM group_members
    ''');
    await customStatement('DROP TABLE group_members');
    await customStatement(
        'ALTER TABLE group_members_v4_new RENAME TO group_members');

    // ── StagedRecipients ───────────────────────────────────────────────────
    await customStatement('''
      CREATE TABLE IF NOT EXISTS staged_recipients_v4_new (
        id              TEXT NOT NULL,
        sessionId       TEXT NOT NULL REFERENCES assisted_sessions(session_id) ON DELETE CASCADE,
        phoneNumber     TEXT NOT NULL,
        contactName     TEXT NOT NULL,
        contactId       TEXT,
        status          TEXT NOT NULL,
        launchSuccess   INTEGER NOT NULL,
        failureReason   TEXT,
        attemptedAt     INTEGER,
        PRIMARY KEY (id)
      )
    ''');
    await customStatement('''
      INSERT OR IGNORE INTO staged_recipients_v4_new
        (id, sessionId, phoneNumber, contactName, contactId,
         status, launchSuccess, failureReason, attemptedAt)
      SELECT
        id, sessionId, phoneNumber, contactName, contactId,
        status, launchSuccess, failureReason, attemptedAt
      FROM staged_recipients
    ''');
    await customStatement('DROP TABLE staged_recipients');
    await customStatement(
        'ALTER TABLE staged_recipients_v4_new RENAME TO staged_recipients');
  }

  Future<void> _seedDefaultTenant() async {
    await into(tenants).insert(
      TenantsCompanion.insert(
        id: 'default-tenant',
        name: 'My Workspace',
        accountType: 'INDIVIDUAL',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(join(dbFolder.path, 'zexano_sms.db'));
    return NativeDatabase(file);
  });
}
