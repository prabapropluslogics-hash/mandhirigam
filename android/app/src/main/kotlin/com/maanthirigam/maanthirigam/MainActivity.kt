package com.maanthirigam.maanthirigam

import android.content.Intent
import android.view.WindowManager
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var deepLinkChannel: MethodChannel? = null
    private var initialLink: String? = null
    private var initialLinkConsumed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "maanthirigam/screen_security")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    val enabled = call.arguments as? Boolean ?: false
                    if (enabled) {
                        window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE
                        )
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }

        initialLink = linkFrom(intent)
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "maanthirigam/deep_links")
            .apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "getInitialLink" -> {
                            val link = if (initialLinkConsumed) null else initialLink
                            initialLinkConsumed = true
                            initialLink = null
                            result.success(link)
                        }
                        "getInstallReferrer" -> fetchInstallReferrer(result)
                        else -> result.notImplemented()
                    }
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        deepLinkChannel?.setMethodCallHandler(null)
        deepLinkChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val link = linkFrom(intent) ?: return
        if (!initialLinkConsumed) {
            initialLink = link
        } else {
            deepLinkChannel?.invokeMethod("onLink", link)
        }
    }

    /** Only https VIEW intents; relaunches from Recents must not replay a link. */
    private fun linkFrom(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        val data = intent.data ?: return null
        if (!"https".equals(data.scheme, ignoreCase = true)) return null
        return data.toString()
    }

    private fun fetchInstallReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(this).build()
        var replied = false
        fun reply(status: String, referrer: String? = null) {
            if (replied) return
            replied = true
            runOnUiThread {
                result.success(mapOf("status" to status, "referrer" to referrer))
            }
            try {
                client.endConnection()
            } catch (e: Exception) {
            }
        }
        try {
            client.startConnection(object : InstallReferrerStateListener {
                override fun onInstallReferrerSetupFinished(responseCode: Int) {
                    when (responseCode) {
                        InstallReferrerClient.InstallReferrerResponse.OK -> {
                            try {
                                reply("ok", client.installReferrer.installReferrer)
                            } catch (e: Exception) {
                                reply("unavailable")
                            }
                        }
                        InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED ->
                            reply("unsupported")
                        else -> reply("unavailable")
                    }
                }

                override fun onInstallReferrerServiceDisconnected() {
                    reply("unavailable")
                }
            })
        } catch (e: Exception) {
            reply("unavailable")
        }
    }
}
