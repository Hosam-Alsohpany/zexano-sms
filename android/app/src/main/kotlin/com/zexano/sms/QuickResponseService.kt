package com.zexano.sms

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log

class QuickResponseService : Service() {
    override fun onBind(intent: Intent): IBinder? {
        Log.d("ZexanoSms", "QuickResponseService bound")
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("ZexanoSms", "QuickResponseService started")
        return START_NOT_STICKY
    }
}
