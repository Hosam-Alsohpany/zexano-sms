package com.zexano.sms

import io.flutter.plugin.common.EventChannel
import android.util.Log

/**
 * Simple singleton event bus that bridges Android broadcast receivers
 * (running outside Flutter's lifecycle) to Flutter's EventChannel.
 *
 * Usage:
 *   - MainActivity registers the EventChannel sink via [setSink].
 *   - SmsSentReceiver / SmsReceiver call [emit] at any time.
 *   - If Flutter Engine is not running the events are silently dropped
 *     (data is already persisted in SQLite, so nothing is lost).
 */
object SmsEventBus {
    private const val TAG = "SmsEventBus"

    @Volatile
    private var sink: EventChannel.EventSink? = null

    fun setSink(s: EventChannel.EventSink?) {
        sink = s
        Log.d(TAG, if (s != null) "EventSink registered" else "EventSink cleared")
    }

    /**
     * Emit a Map event to Flutter.
     * Thread-safe: posts on the main thread via Handler so it is safe to call
     * from any BroadcastReceiver callback.
     */
    fun emit(event: Map<String, Any?>) {
        val s = sink ?: run {
            Log.d(TAG, "emit skipped — no Flutter sink registered")
            return
        }
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            try {
                s.success(event)
            } catch (e: Exception) {
                Log.w(TAG, "emit error: ${e.message}")
            }
        }
    }
}
