package com.zexano.sms

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log
import java.util.UUID

/**
 * Thin SQLite helper that opens **the same database file** Drift uses.
 *
 * Drift stores its database in `getApplicationDocumentsDirectory()` on the
 * Dart side, which maps to `context.filesDir/../app_flutter/zexano_sms.db`
 * on Android (path_provider convention).
 *
 * This helper is intentionally minimal — it only performs the operations
 * needed by [SmsSentReceiver] and [SmsReceiver] when Flutter Engine is not
 * running:
 *   - updateMessageStatus  (sent / failed)
 *   - insertInboundMessage (direction = inbound)
 *
 * Drift will re-use the data on next open because it targets the same file.
 */
object SmsDatabase {

    private const val TAG = "SmsDatabase"

    // Must match Drift's schemaVersion exactly.
    // Drift writes user_version = schemaVersion to the SQLite header.
    // If this value is lower than user_version, SQLiteOpenHelper calls
    // onDowngrade() which throws by default — a hard crash.
    // Rule: always keep this in sync with AppDatabase.schemaVersion in local_database.dart.
    private const val DB_VERSION = 6  // was 5 — caused onDowngrade() crash
    private const val TABLE = "message_history"

    fun open(context: Context): Helper =
        Helper(context).also { it.writableDatabase } // trigger onCreate if needed

    class Helper(context: Context) : SQLiteOpenHelper(
        context,
        dbPath(context),
        null,
        DB_VERSION,
    ) {
        /**
         * We don't create the schema here — Drift handles that.
         * If the DB doesn't exist yet, Drift will create it on first Flutter open.
         * This path is reached only when Drift has already initialised the DB.
         */
        override fun onCreate(db: SQLiteDatabase) = Unit

        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit

        // ── DML operations ───────────────────────────────────────────────────

        fun updateMessageStatus(messageId: String, status: String, sentAt: Long?) {
            val newPriority = when (status) {
                "delivered" -> 5
                "sent", "completed" -> 4
                "failed" -> 3
                "sending", "in_progress" -> 2
                "queued" -> 1
                else -> 0
            }

            var oldStatus: String? = null
            try {
                readableDatabase.rawQuery(
                    "SELECT execution_status FROM $TABLE WHERE id = ?",
                    arrayOf(messageId),
                ).use { cursor ->
                    if (cursor.moveToFirst()) {
                        oldStatus = cursor.getString(0)
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not read old status: ${e.message}")
            }

            val sql = """
                UPDATE $TABLE
                SET execution_status = ?,
                    sent_at = CASE WHEN ? IS NOT NULL THEN ? ELSE sent_at END
                WHERE id = ?
                  AND (
                    CASE execution_status
                      WHEN 'delivered' THEN 5
                      WHEN 'sent' THEN 4
                      WHEN 'completed' THEN 4
                      WHEN 'failed' THEN 3
                      WHEN 'sending' THEN 2
                      WHEN 'in_progress' THEN 2
                      WHEN 'queued' THEN 1
                      ELSE 0
                    END <= ?
                  )
            """.trimIndent()

            var rowsAffected = 0
            try {
                val stmt = writableDatabase.compileStatement(sql)
                stmt.bindString(1, status)
                if (sentAt != null) {
                    stmt.bindLong(2, sentAt)
                    stmt.bindLong(3, sentAt)
                } else {
                    stmt.bindNull(2)
                    stmt.bindNull(3)
                }
                stmt.bindString(4, messageId)
                stmt.bindLong(5, newPriority.toLong())
                rowsAffected = stmt.executeUpdateDelete()
            } catch (e: Exception) {
                Log.e(TAG, "updateMessageStatus compileStatement failed, falling back to execSQL: ${e.message}")
                writableDatabase.execSQL(sql, arrayOf(status, sentAt, sentAt, messageId, newPriority))
            }

            Log.i(
                "SMS STATUS",
                "[SMS STATUS] DB UPDATE messageId=$messageId oldStatus=$oldStatus newStatus=$status rowsAffected=$rowsAffected",
            )
        }

        fun insertInboundMessage(
            tenantId: String,
            senderPhone: String,
            body: String,
            receivedAtSeconds: Long,
            contactName: String?,
        ): String {                        // ← returns the row id
            val id = UUID.randomUUID().toString()
            
            // Canonical peerId per architecture contract:
            // e.g. "sms:+967771234567" for phones, "sms:6060" for short codes, "sms:SABAFON" for sender IDs
            val peerId = NormalizationEngine.generatePeerId(senderPhone)
            val sourceType = "inbound"
            
            val cv = ContentValues().apply {
                put("id", id)
                put("tenant_id", tenantId)
                put("batch_id", UUID.randomUUID().toString())   // unique per inbound
                put("contact_name", contactName ?: "")
                put("target_phone", senderPhone)
                put("peer_id", peerId)
                put("is_read", 0)
                put("message_body", body)
                put("channel_type", "sms")
                put("execution_status", "received")
                put("source_type", sourceType)
                put("direction", "inbound")
                put("timestamp", receivedAtSeconds)
                put("received_at", receivedAtSeconds)
            }
            
            writableDatabase.beginTransaction()
            try {
                writableDatabase.insertOrThrow(TABLE, null, cv)
                writableDatabase.setTransactionSuccessful()
            } finally {
                writableDatabase.endTransaction()
            }
            
            Log.d(TAG, "insertInboundMessage: id=$id peerId=$peerId sourceType=$sourceType from=$senderPhone body=${body.take(40)}")
            return id
        }

        companion object {
            fun dbPath(context: Context): String {
                // path_provider on Flutter maps getApplicationDocumentsDirectory()
                // to <dataDir>/app_flutter — same as filesDir/../app_flutter
                val appFlutter = java.io.File(context.filesDir.parent, "app_flutter")
                appFlutter.mkdirs()
                return java.io.File(appFlutter, "zexano_sms.db").absolutePath
            }
        }
    }
}
