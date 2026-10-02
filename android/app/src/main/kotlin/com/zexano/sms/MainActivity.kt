package com.zexano.sms

import android.Manifest
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.provider.Telephony
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingDefaultSmsResult: MethodChannel.Result? = null
    private var pendingSaveFileResult: MethodChannel.Result? = null
    private var pendingSaveContent: String? = null
    private var pendingExternalSmsIntent: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingExternalSmsIntent = extractSmsIntentData(intent)
        Log.d("MainActivity", "onCreate pendingExternalSmsIntent=$pendingExternalSmsIntent")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val data = extractSmsIntentData(intent)
        Log.d("MainActivity", "onNewIntent externalSmsIntent=$data")
        if (data != null) {
            SmsEventBus.emit(data)
            pendingExternalSmsIntent = data
        }
    }

    private fun extractSmsIntentData(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        val action = intent.action ?: return null
        val uri = intent.data

        val isSmsAction = action == Intent.ACTION_SENDTO ||
                          action == Intent.ACTION_VIEW ||
                          action == Intent.ACTION_SEND

        if (!isSmsAction && uri == null) return null

        var phoneNumber: String? = null
        var messageBody: String? = null

        if (uri != null) {
            val scheme = uri.scheme?.lowercase()
            if (scheme == "sms" || scheme == "smsto" || scheme == "mms" || scheme == "mmsto") {
                val ssp = uri.schemeSpecificPart ?: ""
                val queryIdx = ssp.indexOf('?')
                phoneNumber = if (queryIdx != -1) {
                    ssp.substring(0, queryIdx)
                } else {
                    ssp
                }
                try {
                    messageBody = uri.getQueryParameter("body")
                } catch (_: Exception) {}
            }
        }

        if (phoneNumber.isNullOrBlank()) {
            phoneNumber = intent.getStringExtra("address")
                ?: intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
                ?: intent.getStringExtra("android.intent.extra.PHONE_NUMBER")
        }

        if (messageBody.isNullOrBlank()) {
            messageBody = intent.getStringExtra("sms_body")
                ?: intent.getStringExtra(Intent.EXTRA_TEXT)
        }

        phoneNumber = phoneNumber?.trim()?.removePrefix("//")

        if (phoneNumber.isNullOrBlank() && messageBody.isNullOrBlank()) {
            return null
        }

        Log.d("MainActivity", "Extracted external SMS intent: action=$action, phone=$phoneNumber, body=$messageBody")

        return mapOf(
            "type" to "external_sms_intent",
            "phoneNumber" to (phoneNumber ?: ""),
            "messageBody" to (messageBody ?: ""),
            "action" to action
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── MethodChannel ─────────────────────────────────────────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.zexano.sms/sms",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSmsIntent" -> {
                    val data = pendingExternalSmsIntent
                    pendingExternalSmsIntent = null
                    result.success(data)
                }
                "sendSms" -> {
                    val phone = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("messageBody") ?: ""
                    sendSms(phone, message, result)
                }
                "sendSmsWithDelivery" -> {
                    val phone = call.argument<String>("phoneNumber") ?: ""
                    val message = call.argument<String>("messageBody") ?: ""
                    val messageId = call.argument<String>("messageId") ?: ""
                    sendSmsWithDelivery(phone, message, messageId, result)
                }
                "hasSmsPermission" -> {
                    result.success(hasSmsPermission())
                }
                "requestSmsPermission" -> {
                    requestSmsPermission(result)
                }
                "hasContactsPermission" -> {
                    result.success(hasContactsPermission())
                }
                "requestContactsPermission" -> {
                    requestContactsPermission(result)
                }
                "isDefaultSmsApp" -> {
                    result.success(isDefaultSmsApp())
                }
                "requestDefaultSmsApp" -> {
                    requestDefaultSmsApp(result)
                }
                "saveFile" -> {
                    val fileName = call.argument<String>("fileName") ?: "contacts.vcf"
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"
                    val content = call.argument<String>("content") ?: ""
                    saveFile(fileName, mimeType, content, result)
                }
                else -> result.notImplemented()
            }
        }

        // ── EventChannel — real-time events → Flutter ─────────────────────────
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.zexano.sms/incoming",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                SmsEventBus.setSink(events)
            }
            override fun onCancel(arguments: Any?) {
                SmsEventBus.setSink(null)
            }
        })
    }

    private fun hasSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun getSmsManager(): SmsManager {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            @Suppress("DEPRECATION")
            val subId = SubscriptionManager.getDefaultSmsSubscriptionId()
            if (subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                SmsManager.getSmsManagerForSubscriptionId(subId)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }
    }

    private fun isDefaultSmsApp(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(android.app.role.RoleManager::class.java)
            val held = roleManager.isRoleHeld(android.app.role.RoleManager.ROLE_SMS)
            Log.d(TAG, "isDefaultSmsApp: RoleManager held=$held")
            held
        } else {
            val defaultPkg = Telephony.Sms.getDefaultSmsPackage(this)
            val result = defaultPkg == packageName
            Log.d(TAG, "isDefaultSmsApp: default=$defaultPkg mine=$packageName result=$result")
            result
        }
    }

    private fun requestDefaultSmsApp(result: MethodChannel.Result) {
        Log.d(TAG, "requestDefaultSmsApp called")
        if (isDefaultSmsApp()) {
            Log.d(TAG, "Already default SMS app")
            result.success(true)
            return
        }

        var intentLaunched = false

        // 1) RoleManager (API 29+): shows native system dialog — use startActivityForResult
        //    so Flutter side waits for the user's actual choice before receiving a result.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val roleManager = getSystemService(android.app.role.RoleManager::class.java)
                if (roleManager.isRoleAvailable(android.app.role.RoleManager.ROLE_SMS)) {
                    val intent = roleManager.createRequestRoleIntent(
                        android.app.role.RoleManager.ROLE_SMS
                    )
                    pendingDefaultSmsResult = result
                    @Suppress("DEPRECATION")
                    startActivityForResult(intent, REQUEST_DEFAULT_SMS_CODE)
                    Log.d(TAG, "RoleManager intent launched via startActivityForResult")
                    intentLaunched = true
                } else {
                    Log.d(TAG, "RoleManager: ROLE_SMS not available")
                }
            } catch (e: Exception) {
                Log.w(TAG, "RoleManager failed: ${e.message}")
            }
        }

        // 2) ACTION_CHANGE_DEFAULT (API < 29 or RoleManager not available)
        if (!intentLaunched) {
            try {
                val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
                pendingDefaultSmsResult = result
                @Suppress("DEPRECATION")
                startActivityForResult(intent, REQUEST_DEFAULT_SMS_CODE)
                Log.d(TAG, "ACTION_CHANGE_DEFAULT launched via startActivityForResult")
                intentLaunched = true
            } catch (e: Exception) {
                Log.d(TAG, "ACTION_CHANGE_DEFAULT failed: ${e.message}")
            }
        }

        // 3) ACTION_MANAGE_DEFAULT_APPS_SETTINGS fallback (MIUI, etc.)
        if (!intentLaunched) {
            try {
                val fallback = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(fallback)
                Log.d(TAG, "ACTION_MANAGE_DEFAULT_APPS_SETTINGS launched")
                intentLaunched = true
                result.success(false)
            } catch (e: Exception) {
                Log.d(TAG, "ACTION_MANAGE_DEFAULT_APPS_SETTINGS failed: ${e.message}")
            }
        }

        // 4) Xiaomi/MIUI-specific: app details page
        if (!intentLaunched && Build.MANUFACTURER.equals("Xiaomi", ignoreCase = true)) {
            try {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                Log.d(TAG, "APPLICATION_DETAILS_SETTINGS launched")
                intentLaunched = true
                result.success(false)
            } catch (e: Exception) {
                Log.d(TAG, "APPLICATION_DETAILS_SETTINGS failed: ${e.message}")
            }
        }

        // 5) Generic fallback: main settings
        if (!intentLaunched) {
            try {
                val generic = Intent(Settings.ACTION_SETTINGS)
                generic.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(generic)
                Log.d(TAG, "ACTION_SETTINGS launched")
                result.success(false)
            } catch (e: Exception) {
                Log.d(TAG, "ACTION_SETTINGS failed: ${e.message}")
                result.success(false)
            }
        }

        Log.d(TAG, "requestDefaultSmsApp intentLaunched=$intentLaunched")
    }

    private fun sendSms(
        phone: String,
        message: String,
        result: MethodChannel.Result,
    ) {
        if (!hasSmsPermission()) {
            result.success(
                mapOf(
                    "success" to false,
                    "error" to "permission_denied",
                ),
            )
            return
        }
        if (!isDefaultSmsApp()) {
            result.success(
                mapOf(
                    "success" to false,
                    "error" to "app_not_default_sms",
                ),
            )
            return
        }
        val smsManager = getSmsManager()
        Log.d(TAG, "Sending SMS to $phone")
        @Suppress("DEPRECATION")
        smsManager.sendTextMessage(phone, null, message, null, null)
        Log.d(TAG, "SMS queued to $phone")
        result.success(mapOf("success" to true))
    }

    /**
     * Sends an SMS with a PendingIntent that carries [messageId].
     * [SmsSentReceiver] catches the broadcast and updates the exact DB row to
     * "sent" or "failed" — no Flutter Engine required at delivery time.
     *
     * Returns immediately with {"success": true, "status": "queued"} so the
     * Flutter side can record the initial state without blocking.
     */
    @Suppress("DEPRECATION")
    private fun sendSmsWithDelivery(
        phone: String,
        message: String,
        messageId: String,
        result: MethodChannel.Result,
    ) {
        if (!hasSmsPermission()) {
            result.success(mapOf("success" to false, "error" to "permission_denied"))
            return
        }
        if (!isDefaultSmsApp()) {
            result.success(mapOf("success" to false, "error" to "app_not_default_sms"))
            return
        }
        try {
            // ── Step 1: Mark as 'sending' BEFORE dispatch ────────────────────────
            try {
                val db = SmsDatabase.open(this)
                db.updateMessageStatus(messageId, "sending", null)
                Log.d(TAG, "sendSmsWithDelivery: marked id=$messageId as 'sending'")
            } catch (e: Exception) {
                Log.w(TAG, "Could not write 'sending' status: ${e.message}")
            }

            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            else
                PendingIntent.FLAG_UPDATE_CURRENT

            val smsManager = getSmsManager()
            val parts = smsManager.divideMessage(message)
            val totalParts = parts.size

            if (totalParts > 1) {
                // ── Multipart SMS Path ───────────────────────────────────────────
                Log.d(TAG, "sendSmsWithDelivery: multipart ($totalParts parts) phone=$phone id=$messageId")
                val sentPis = ArrayList<PendingIntent>(totalParts)
                val deliveredPis = ArrayList<PendingIntent>(totalParts)

                for (i in 0 until totalParts) {
                    val sentIntent = Intent(SmsSentReceiver.ACTION_SMS_SENT, null, this, SmsSentReceiver::class.java).apply {
                        data = Uri.parse("sms-status://$messageId/sent/$i")
                        putExtra(SmsSentReceiver.EXTRA_MESSAGE_ID, messageId)
                        putExtra(SmsSentReceiver.EXTRA_PHONE, phone)
                        putExtra(SmsSentReceiver.EXTRA_IS_DELIVERY_REPORT, false)
                        putExtra(SmsSentReceiver.EXTRA_PART_INDEX, i)
                        putExtra(SmsSentReceiver.EXTRA_TOTAL_PARTS, totalParts)
                    }
                    val sentPi = PendingIntent.getBroadcast(
                        this,
                        (messageId + "_sent_" + i).hashCode(),
                        sentIntent,
                        flags,
                    )
                    sentPis.add(sentPi)

                    val deliveredIntent = Intent(SmsSentReceiver.ACTION_SMS_DELIVERY, null, this, SmsSentReceiver::class.java).apply {
                        data = Uri.parse("sms-status://$messageId/delivered/$i")
                        putExtra(SmsSentReceiver.EXTRA_MESSAGE_ID, messageId)
                        putExtra(SmsSentReceiver.EXTRA_PHONE, phone)
                        putExtra(SmsSentReceiver.EXTRA_IS_DELIVERY_REPORT, true)
                        putExtra(SmsSentReceiver.EXTRA_PART_INDEX, i)
                        putExtra(SmsSentReceiver.EXTRA_TOTAL_PARTS, totalParts)
                    }
                    val deliveredPi = PendingIntent.getBroadcast(
                        this,
                        (messageId + "_deliv_" + i).hashCode(),
                        deliveredIntent,
                        flags,
                    )
                    deliveredPis.add(deliveredPi)
                }

                smsManager.sendMultipartTextMessage(phone, null, parts, sentPis, deliveredPis)
            } else {
                // ── Single Part SMS Path ─────────────────────────────────────────
                Log.d(TAG, "sendSmsWithDelivery: single part phone=$phone id=$messageId")
                val sentIntent = Intent(SmsSentReceiver.ACTION_SMS_SENT, null, this, SmsSentReceiver::class.java).apply {
                    data = Uri.parse("sms-status://$messageId/sent/0")
                    putExtra(SmsSentReceiver.EXTRA_MESSAGE_ID, messageId)
                    putExtra(SmsSentReceiver.EXTRA_PHONE, phone)
                    putExtra(SmsSentReceiver.EXTRA_IS_DELIVERY_REPORT, false)
                    putExtra(SmsSentReceiver.EXTRA_PART_INDEX, 0)
                    putExtra(SmsSentReceiver.EXTRA_TOTAL_PARTS, 1)
                }
                val sentPi = PendingIntent.getBroadcast(
                    this,
                    (messageId + "_sent").hashCode(),
                    sentIntent,
                    flags,
                )

                val deliveredIntent = Intent(SmsSentReceiver.ACTION_SMS_DELIVERY, null, this, SmsSentReceiver::class.java).apply {
                    data = Uri.parse("sms-status://$messageId/delivered/0")
                    putExtra(SmsSentReceiver.EXTRA_MESSAGE_ID, messageId)
                    putExtra(SmsSentReceiver.EXTRA_PHONE, phone)
                    putExtra(SmsSentReceiver.EXTRA_IS_DELIVERY_REPORT, true)
                    putExtra(SmsSentReceiver.EXTRA_PART_INDEX, 0)
                    putExtra(SmsSentReceiver.EXTRA_TOTAL_PARTS, 1)
                }
                val deliveredPi = PendingIntent.getBroadcast(
                    this,
                    (messageId + "_deliv").hashCode(),
                    deliveredIntent,
                    flags,
                )

                smsManager.sendTextMessage(phone, null, message, sentPi, deliveredPi)
            }

            result.success(mapOf("success" to true, "status" to "queued"))
        } catch (e: Exception) {
            Log.e(TAG, "sendSmsWithDelivery error: ${e.message}", e)
            result.success(mapOf("success" to false, "error" to e.message))
        }
    }

    private fun requestSmsPermission(result: MethodChannel.Result) {
        if (hasSmsPermission()) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.SEND_SMS),
            SMS_PERMISSION_REQUEST_CODE,
        )
    }

    private fun hasContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, Manifest.permission.READ_CONTACTS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestContactsPermission(result: MethodChannel.Result) {
        if (hasContactsPermission()) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_CONTACTS),
            CONTACTS_PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            SMS_PERMISSION_REQUEST_CODE, CONTACTS_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
                pendingPermissionResult?.success(granted)
                pendingPermissionResult = null
            }
        }
    }

    private fun saveFile(fileName: String, mimeType: String, content: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = mimeType
                putExtra(Intent.EXTRA_TITLE, fileName)
            }
            pendingSaveFileResult = result
            pendingSaveContent = content
            @Suppress("DEPRECATION")
            startActivityForResult(intent, REQUEST_SAVE_FILE_CODE)
        } catch (e: Exception) {
            Log.e(TAG, "saveFile error: ${e.message}", e)
            result.error("SAVE_FAILED", e.message, null)
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_SAVE_FILE_CODE -> {
                if (resultCode == android.app.Activity.RESULT_OK && data?.data != null) {
                    val uri = data.data!!
                    try {
                        contentResolver.openOutputStream(uri)?.use { os ->
                            os.write(pendingSaveContent?.toByteArray(Charsets.UTF_8) ?: ByteArray(0))
                            os.flush()
                        }
                        pendingSaveFileResult?.success(mapOf("status" to "success", "uri" to uri.toString()))
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to write to uri $uri: ${e.message}", e)
                        pendingSaveFileResult?.error("SAVE_FAILED", e.message, null)
                    }
                } else {
                    pendingSaveFileResult?.success(mapOf("status" to "cancelled"))
                }
                pendingSaveFileResult = null
                pendingSaveContent = null
            }
            REQUEST_DEFAULT_SMS_CODE -> {
                val isNowDefault = isDefaultSmsApp()
                Log.d(TAG, "onActivityResult: REQUEST_DEFAULT_SMS_CODE resultCode=$resultCode isNowDefault=$isNowDefault")
                pendingDefaultSmsResult?.success(isNowDefault)
                pendingDefaultSmsResult = null
            }
        }
    }

    companion object {
        private const val TAG = "ZexanoSms"
        private const val SMS_PERMISSION_REQUEST_CODE = 1001
        private const val CONTACTS_PERMISSION_REQUEST_CODE = 1002
        private const val REQUEST_DEFAULT_SMS_CODE = 1003
        private const val REQUEST_SAVE_FILE_CODE = 1004
    }
}
