package ru.tezvpn.tezvpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import ru.tezvpn.tezvpn.vpn.VpnController

class MainActivity : FlutterActivity() {
    private val channel = "ru.tezvpn.app/vpn"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private lateinit var vpn: VpnController
    private var pendingPrepare: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        vpn = VpnController(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "prepare" -> {
                    val intent = VpnService.prepare(this)
                    if (intent == null) {
                        result.success(true)
                    } else {
                        pendingPrepare = result
                        startActivityForResult(intent, 42)
                    }
                }
                "connect" -> {
                    val conf = call.argument<String>("conf") ?: ""
                    val protocol = call.argument<String>("protocol") ?: "awg"
                    if (protocol != "awg") {
                        result.error(
                            "vpn",
                            "Протокол сохранён. Туннель Xray и Hysteria2 в этой версии ещё не встроен",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    scope.launch {
                        try {
                            vpn.connect(conf)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("vpn", e.message, null)
                        }
                    }
                }
                "disconnect" -> {
                    scope.launch {
                        try {
                            vpn.disconnect()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("vpn", e.message, null)
                        }
                    }
                }
                "isUp" -> result.success(vpn.isUp())
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Activity result for VPN permission")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 42) {
            pendingPrepare?.success(resultCode == Activity.RESULT_OK)
            pendingPrepare = null
        }
    }
}
