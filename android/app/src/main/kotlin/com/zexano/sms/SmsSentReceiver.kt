package com.zexano.sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.Activity
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SmsMessage
import android.util.Log
import java.util.concurrent.ConcurrentHashMap

/**
 * Receives two distinct PendingIntent broadcasts for each SMS dispatched:
 *
 *   1. **Sent report** (`ACTION_SMS_SENT`):
 *      Fires when the SMS reaches the carrier base station / SMSC.
 *      RESULT_OK confirms carrier acceptance → updates row to 'sent'.
 *      CRITICAL INVARIANT: SENT RESULT_OK is NEVER 'delivered'.
 *
 *   2. **Delivery report** (`ACTION_SMS_DELIVERY`):
 *      Fires when the recipient device confirms receipt via network SMS-STATUS-REPORT.
 *      Decodes 3GPP (GSM) or 3GPP2 (CDMA) PDU TP-Status.
 *      Only positive delivery promotes status: 'sent' → 'delivered'.
 *      Unparseable / missing / pending reports remain 'sent' (never promote).
 */
class SmsSentReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val messageId = intent.getStringExtra(EXTRA_MESSAGE_ID) ?: run {
            Log.w(TAG, "SmsSentReceiver: missing messageId extra")
            return
        }
        val phone            = intent.getStringExtra(EXTRA_PHONE) ?: ""
        val isDeliveryReport = intent.getBooleanExtra(EXTRA_IS_DELIVERY_REPORT, false)
            || intent.action == ACTION_SMS_DELIVERY

        if (isDeliveryReport) {
            handleDeliveryReport(context, intent, messageId, phone)
        } else {
            handleSentReport(context, messageId, phone)
        }
    }

    // ── Sent report (carrier ACK) ────────────────────────────────────────────

    private fun handleSentReport(context: Context, messageId: String, phone: String) {
        Log.i(TAG_STATUS, "[SMS STATUS] type=SENT messageId=$messageId phone=$phone resultCode=$resultCode")

        val newStatus = when (resultCode) {
            Activity.RESULT_OK -> {
                // Invariant: SENT RESULT_OK confirms submission to network, NEVER delivered!
                "sent"
            }
            SmsManager.RESULT_ERROR_NO_SERVICE,
            SmsManager.RESULT_ERROR_NULL_PDU,
            SmsManager.RESULT_ERROR_RADIO_OFF -> {
                "failed"
            }
            else -> {
                "failed"
            }
        }

        updateMessageStatus(context, messageId, newStatus)

        SmsEventBus.emit(
            mapOf(
                "type"      to "sms_status_update",
                "messageId" to messageId,
                "status"    to newStatus,
            )
        )
        Log.i(TAG_STATUS, "[SMS STATUS] EVENT EMITTED messageId=$messageId status=$newStatus")
    }

    // ── Delivery report (device confirmation) ────────────────────────────────

    private fun handleDeliveryReport(context: Context, intent: Intent, messageId: String, phone: String) {
        val pdu = intent.getByteArrayExtra("pdu")
        val format = intent.getStringExtra("format")
        val partIndex = intent.getIntExtra(EXTRA_PART_INDEX, 0)
        val totalParts = intent.getIntExtra(EXTRA_TOTAL_PARTS, 1)

        var tpStatus: Int? = null
        var mappedStatus: String? = null

        if (pdu != null) {
            try {
                val sms = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    SmsMessage.createFromPdu(pdu, format)
                } else {
                    @Suppress("DEPRECATION")
                    SmsMessage.createFromPdu(pdu)
                }

                if (sms != null) {
                    val rawStatus = sms.status
                    tpStatus = rawStatus

                    // Format-aware evaluation:
                    if ("3gpp2".equals(format, ignoreCase = true)) {
                        // CDMA (e.g. Yemen Mobile)
                        // Error class in bits 24..31, status code in bits 16..23
                        val errorClass = (rawStatus shr 24) and 0x03
                        when {
                            rawStatus == 0 || errorClass == 0 -> {
                                // Positive delivery
                                mappedStatus = "delivered"
                            }
                            errorClass == 2 -> {
                                // Temporary error / pending: remain 'sent'
                                mappedStatus = null
                            }
                            errorClass == 3 -> {
                                // Permanent failure
                                mappedStatus = "failed"
                            }
                            else -> {
                                // Ambiguous / unparseable: remain 'sent'
                                mappedStatus = null
                            }
                        }
                    } else {
                        // GSM (3GPP TS 23.040 Section 9.2.3.15 TP-Status)
                        when {
                            rawStatus in 0..31 -> {
                                // 0x00 .. 0x1F: Short message transaction completed (Delivered!)
                                mappedStatus = "delivered"
                            }
                            rawStatus in 32..63 -> {
                                // 0x20 .. 0x3F: Temporary error, SC still trying (e.g. phone off)
                                // Invariant: remain 'sent'
                                mappedStatus = null
                            }
                            rawStatus in 64..127 -> {
                                // 0x40 .. 0x7F: Permanent error
                                mappedStatus = "failed"
                            }
                            else -> {
                                // Invariant: Unparseable delivery report → remain 'sent' (never falsely mark delivered)
                                mappedStatus = null
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to parse delivery PDU: ${e.message}", e)
                // Invariant: Unparseable delivery report → remain 'sent'
                mappedStatus = null
            }
        } else {
            // No PDU provided:
            // Invariant: Missing PDU delivery report is ambiguous → remain 'sent', never assume delivered!
            mappedStatus = null
        }

        Log.i(
            TAG_STATUS,
            "[SMS STATUS] type=DELIVERY messageId=$messageId phone=$phone resultCode=$resultCode " +
                "pduPresent=${pdu != null} format=$format tpStatus=$tpStatus " +
                "partIndex=$partIndex totalParts=$totalParts mappedStatus=${mappedStatus ?: "remain_sent"}"
        )

        if (mappedStatus != null) {
            if (totalParts > 1) {
                if (mappedStatus == "failed") {
                    // Any segment permanent failure fails the message
                    updateMessageStatus(context, messageId, "failed")
                    SmsEventBus.emit(
                        mapOf(
                            "type"      to "sms_status_update",
                            "messageId" to messageId,
                            "status"    to "failed",
                        )
                    )
                    Log.i(TAG_STATUS, "[SMS STATUS] EVENT EMITTED messageId=$messageId status=failed")
                } else if (mappedStatus == "delivered") {
                    // Track delivered segments
                    val deliveredSet = multipartDeliveredParts.getOrPut(messageId) {
                        ConcurrentHashMap.newKeySet()
                    }
                    deliveredSet.add(partIndex)

                    if (deliveredSet.size >= totalParts) {
                        multipartDeliveredParts.remove(messageId)
                        updateMessageStatus(context, messageId, "delivered")
                        SmsEventBus.emit(
                            mapOf(
                                "type"      to "sms_status_update",
                                "messageId" to messageId,
                                "status"    to "delivered",
                            )
                        )
                        Log.i(TAG_STATUS, "[SMS STATUS] EVENT EMITTED messageId=$messageId status=delivered (all $totalParts parts delivered)")
                    } else {
                        Log.i(TAG_STATUS, "[SMS STATUS] Multipart partial delivery: ${deliveredSet.size}/$totalParts parts confirmed id=$messageId")
                    }
                }
            } else {
                // Single part message
                updateMessageStatus(context, messageId, mappedStatus)
                SmsEventBus.emit(
                    mapOf(
                        "type"      to "sms_status_update",
                        "messageId" to messageId,
                        "status"    to mappedStatus,
                    )
                )
                Log.i(TAG_STATUS, "[SMS STATUS] EVENT EMITTED messageId=$messageId status=$mappedStatus")
            }
        }
    }

    // ── SQLite direct write ──────────────────────────────────────────────────

    private fun updateMessageStatus(context: Context, messageId: String, status: String) {
        try {
            val db     = SmsDatabase.open(context)
            val sentAt = if (status == "sent") System.currentTimeMillis() / 1000L else null
            db.updateMessageStatus(messageId, status, sentAt)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to update DB: ${e.message}", e)
        }
    }

    companion object {
        const val ACTION_SMS_SENT         = "com.zexano.sms.SMS_SENT"
        const val ACTION_SMS_DELIVERY     = "com.zexano.sms.SMS_DELIVERY"

        const val EXTRA_MESSAGE_ID        = "messageId"
        const val EXTRA_PHONE             = "phone"
        const val EXTRA_IS_DELIVERY_REPORT = "isDeliveryReport"
        const val EXTRA_PART_INDEX        = "partIndex"
        const val EXTRA_TOTAL_PARTS       = "totalParts"

        private const val TAG = "SmsSentReceiver"
        private const val TAG_STATUS = "SMS STATUS"

        // Tracks delivered parts for multipart messages in flight
        private val multipartDeliveredParts = ConcurrentHashMap<String, MutableSet<Int>>()
    }
}
