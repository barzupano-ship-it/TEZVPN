package ru.tezvpn.tezvpn.vpn

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
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
