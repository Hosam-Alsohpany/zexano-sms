package com.zexano.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsMessage
import android.util.Log

/**
 * Receives incoming SMS when Zexano is the default SMS app.
 *
 * Strategy (robust, no Flutter Engine dependency):
 *   1. Extract sender, body, and accurate timestamp via SmsMessage.timestampMillis.
 *   2. Write directly to the SQLite file Drift uses → no data lost if app is killed.
 *   3. If Flutter Engine is running, also push the event via SmsEventBus so the
 *      History screen refreshes in real time without the user having to reopen.
 *
 * NOTE: We register for SMS_DELIVER only (not SMS_RECEIVED).
 * When this app is the default SMS app, Android sends BOTH broadcasts for every
 * inbound message — processing SMS_RECEIVED as well would insert every message twice.
 * SMS_DELIVER is the authoritative broadcast for default SMS apps.
 */
class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // Accept only the broadcast intended for the default SMS app.
        if (intent.action != Telephony.Sms.Intents.SMS_DELIVER_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        var sender: String? = null
        var receivedAtSeconds = 0L
        val bodyBuilder = java.lang.StringBuilder()

        for (message in messages) {
            if (message == null) continue
            if (sender == null) {
                sender = message.displayOriginatingAddress ?: message.originatingAddress
                receivedAtSeconds = message.timestampMillis / 1000L
            }
            bodyBuilder.append(message.displayMessageBody ?: message.messageBody ?: "")
        }

        if (sender == null) return
        val body = bodyBuilder.toString()
        if (body.isEmpty()) return

        Log.d(TAG, "Inbound SMS from=$sender body=${body.take(40)}")

        // 1) Persist directly to SQLite — works even when Flutter Engine is off.
        //    The UUID is generated here (single source of truth) and carried in
        //    the EventBus payload so Flutter can perform an INSERT OR IGNORE with
        //    the exact same id — making the dual-write truly idempotent.
        var rowId: String? = null
        try {
            val db = SmsDatabase.open(context)
            rowId = db.insertInboundMessage(
                tenantId = DEFAULT_TENANT_ID,
                senderPhone = sender,
                body = body,
                receivedAtSeconds = receivedAtSeconds,
                contactName = null, // Flutter resolves the name on open
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist inbound SMS: ${e.message}", e)
        }

        // 2) If Flutter is foregrounded, notify UI immediately.
        //    Flutter will attempt INSERT OR IGNORE using the same rowId,
        //    so even if both paths run, the database ends up with exactly one row.
        SmsEventBus.emit(
            mapOf(
                "type"       to "inbound_sms",
                "id"         to (rowId ?: ""),   // ← same UUID native wrote
                "sender"     to sender,
                "body"       to body,
                "receivedAt" to receivedAtSeconds,
            )
        )
    }

    companion object {
        private const val TAG = "SmsReceiver"
        private const val DEFAULT_TENANT_ID = "default-tenant"
    }
}
