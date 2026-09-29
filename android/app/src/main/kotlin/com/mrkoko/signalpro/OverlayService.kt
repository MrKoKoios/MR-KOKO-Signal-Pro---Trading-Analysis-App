package com.mrkoko.signalpro

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log

class MRKokoScanService : Service() {

    companion object {
        const val ACTION_START_SCAN =
            "com.mrkoko.signalpro.START_SCAN"

        const val ACTION_STOP_SCAN =
            "com.mrkoko.signalpro.STOP_SCAN"

        private const val TAG = "MR_KOKO_SCAN"
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {

        when (intent?.action) {

            ACTION_START_SCAN -> {
                MarketAccessibilityService.getInstance()
                    ?.startScan()

                Log.d(TAG, "SCAN STARTED")
            }

            ACTION_STOP_SCAN -> {
                MarketAccessibilityService.getInstance()
                    ?.stopScan()

                Log.d(TAG, "SCAN STOPPED")
            }
        }

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
