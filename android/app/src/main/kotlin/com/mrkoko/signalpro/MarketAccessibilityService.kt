package com.mrkoko.signalpro

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class MarketAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "MR_KOKO_ACCESSIBILITY"

        private var serviceInstance: MarketAccessibilityService? = null

        var scanning: Boolean = false

        @JvmStatic
        fun getInstance(): MarketAccessibilityService? {
            return serviceInstance
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()

        serviceInstance = this

        Log.d(
            TAG,
            "MR KOKO Accessibility connected"
        )
    }

    override fun onAccessibilityEvent(
        event: AccessibilityEvent?
    ) {
        if (!scanning) return

        if (event == null) return

        Log.d(
            TAG,
            "Screen event: ${event.eventType}"
        )
    }

    override fun onInterrupt() {
        scanning = false

        Log.d(
            TAG,
            "Accessibility interrupted"
        )
    }

    override fun onDestroy() {
        scanning = false
        serviceInstance = null

        super.onDestroy()
    }

    fun startScan() {
        scanning = true

        Log.d(
            TAG,
            "Scanning enabled"
        )
    }

    fun stopScan() {
        scanning = false

        Log.d(
            TAG,
            "Scanning disabled"
        )
    }
}
