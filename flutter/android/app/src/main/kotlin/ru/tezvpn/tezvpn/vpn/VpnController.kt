package ru.tezvpn.tezvpn.vpn

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import android.content.Intent
import android.content.pm.PackageManager
import org.amnezia.awg.backend.Backend
import org.amnezia.awg.backend.GoBackend
import org.amnezia.awg.backend.NoopTunnelActionHandler
import org.amnezia.awg.backend.Tunnel
import org.amnezia.awg.config.Config
import java.io.ByteArrayInputStream

class VpnController(context: Context) {
    private val appContext = context.applicationContext
    private val backend = GoBackend(appContext, NoopTunnelActionHandler())
    private val tunnel = TezTunnel()

    fun isUp(): Boolean = tunnel.state == Tunnel.State.UP

    suspend fun setKillSwitch(enabled: Boolean) {
        withContext(Dispatchers.IO) {
            val mode: Backend.BackendMode = if (enabled) {
                Backend.BackendMode.KillSwitch(setOf("0.0.0.0/0", "::/0"), false, true)
            } else {
                Backend.BackendMode.Inactive.INSTANCE
            }
            backend.setBackendMode(mode)
        }
    }

    fun launchableApps(): List<Map<String, String>> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val seen = linkedSetOf<String>()
        return appContext.packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
            .mapNotNull { info ->
                val pkg = info.activityInfo?.packageName ?: return@mapNotNull null
                if (pkg == appContext.packageName || !seen.add(pkg)) return@mapNotNull null
                mapOf("package" to pkg, "label" to info.loadLabel(appContext.packageManager).toString())
            }
            .sortedBy { it["label"]?.lowercase() }
    }

    suspend fun connect(conf: String) {
        withContext(Dispatchers.IO) {
            val config = Config.parse(ByteArrayInputStream(conf.toByteArray(Charsets.UTF_8)))
            backend.setState(tunnel, Tunnel.State.UP, config)
        }
    }

    suspend fun disconnect() {
        withContext(Dispatchers.IO) {
            backend.setState(tunnel, Tunnel.State.DOWN, null)
        }
    }
}
