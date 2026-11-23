package tn.supcom.phishguard

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Receives text from the Android share menu ("Share" -> PhishGuard)
 * and hands it to Flutter through the "phishguard/share" channel.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var initialShared: Map<String, String?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) initialShared = readShared(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "phishguard/share").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialSharedText") {
                    result.success(initialShared)
                    initialShared = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readShared(intent)?.let { channel?.invokeMethod("onSharedText", it) }
    }

    private fun readShared(intent: Intent?): Map<String, String?>? {
        if (intent?.action != Intent.ACTION_SEND || intent.type?.startsWith("text/") != true) return null
        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return null
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)
        val full = if (subject.isNullOrBlank() || text.contains(subject)) text else "$subject\n$text"
        return mapOf("text" to full, "sourceApp" to referrer?.host)
    }
}
