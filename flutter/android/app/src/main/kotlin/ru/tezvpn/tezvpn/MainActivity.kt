package ru.tezvpn.tezvpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import ru.tezvpn.tezvpn.vpn.VpnController
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    private val channel = "ru.tezvpn.app/vpn"
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private lateinit var vpn: VpnController
    private var pendingPrepare: MethodChannel.Result? = null
    private var pendingFile: MethodChannel.Result? = null

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
                "setKillSwitch" -> {
                    val enabled = call.argument<Boolean>("enabled") == true
                    scope.launch {
                        try {
                            vpn.setKillSwitch(enabled)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("vpn", e.message, null)
                        }
                    }
                }
                "launchableApps" -> result.success(vpn.launchableApps())
                "traffic" -> result.success(tunnelTraffic())
                "pickSupportFile" -> {
                    pendingFile?.success(null)
                    pendingFile = result
                    val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "*/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }
                    startActivityForResult(Intent.createChooser(intent, "Файл"), 43)
                }
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
            return
        }
        if (requestCode != 43) return
        val reply = pendingFile
        pendingFile = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            reply?.success(null)
            return
        }
        scope.launch {
            try {
                val payload = withContext(Dispatchers.IO) {
                    var name = "file"
                    contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            name = cursor.getString(0) ?: name
                        }
                    }
                    val input = contentResolver.openInputStream(uri)
                        ?: throw IllegalStateException("Файл не получен.")
                    val out = ByteArrayOutputStream()
                    input.use { stream ->
                        val chunk = ByteArray(8192)
                        var total = 0
                        while (true) {
                            val n = stream.read(chunk)
                            if (n < 0) break
                            total += n
                            if (total > 20 * 1024 * 1024) {
                                throw IllegalStateException("Файл больше 20 МБ.")
                            }
                            out.write(chunk, 0, n)
                        }
                    }
                    mapOf("name" to name, "bytes" to out.toByteArray())
                }
                reply?.success(payload)
            } catch (e: Exception) {
                reply?.error("file", e.message, null)
            }
        }
    }
}

private fun tunnelTraffic(): Map<String, Long> {
    var upload = 0L
    var download = 0L
    val text = try {
        File("/proc/net/dev").readText()
    } catch (_: Exception) {
        return mapOf("up" to 0L, "down" to 0L)
    }
    for (raw in text.lineSequence()) {
        val line = raw.trim()
        val colon = line.indexOf(':')
        if (colon <= 0) continue
        val name = line.substring(0, colon)
        if (!name.startsWith("tun")) continue
        val parts = line.substring(colon + 1).trim().split(Regex("\\s+"))
        if (parts.size < 9) continue
        val received = parts[0].toLongOrNull() ?: continue
        val sent = parts[8].toLongOrNull() ?: continue
        download += received
        upload += sent
    }
    return mapOf("up" to upload, "down" to download)
}
