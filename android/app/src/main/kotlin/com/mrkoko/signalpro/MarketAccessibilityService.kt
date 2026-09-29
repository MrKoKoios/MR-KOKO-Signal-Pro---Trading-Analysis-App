package com.mrkoko.signalpro

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class MarketAccessibilityService :
    AccessibilityService() {

    companion object {
        private const val TAG = "MRKOKO_ACCESSIBILITY"

        var instance:
            MarketAccessibilityService? = null

        var scanning: Boolean = false
    }

    override fun onServiceConnected() {
        super.onServiceConnected()

        instance = this

        Log.d(
            TAG,
            "MR KOKO Accessibility Service connected"
        )
    }

    override fun onAccessibilityEvent(
        event: AccessibilityEvent?
    ) {

        if (!scanning) {
            return
        }

        if (event == null) {
            return
        }

        Log.d(
            TAG,
            "Screen event received: ${event.eventType}"
        )
    }

    override fun onInterrupt() {
        Log.d(
            TAG,
            "Accessibility service interrupted"
        )

        scanning = false
    }

    override fun onDestroy() {
        scanning = false
        instance = null

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
