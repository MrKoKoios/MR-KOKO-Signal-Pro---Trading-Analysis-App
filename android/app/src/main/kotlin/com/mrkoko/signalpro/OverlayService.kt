package com.mrkoko.signalpro

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log

class OverlayService : Service() {

    companion object {
        const val ACTION_START_SCAN =
            "com.mrkoko.signalpro.START_SCAN"

        const val ACTION_STOP_SCAN =
            "com.mrkoko.signalpro.STOP_SCAN"

        private const val TAG = "MRKOKO_OVERLAY"
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        when (intent?.action) {

            ACTION_START_SCAN -> {
                Log.d(TAG, "Screen scan started")
            }

            ACTION_STOP_SCAN -> {
                Log.d(TAG, "Screen scan stopped")
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
