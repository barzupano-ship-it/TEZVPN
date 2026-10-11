package ru.tezvpn.tezvpn.vpn

import org.amnezia.awg.backend.Tunnel

class TezTunnel : Tunnel {
    @Volatile
    var state: Tunnel.State = Tunnel.State.DOWN
        private set

    override fun getName(): String = "tezvpn"

    override fun onStateChange(newState: Tunnel.State) {
        state = newState
    }

    override fun isIpv4ResolutionPreferred(): Boolean = true

    override fun isMetered(): Boolean = false
}
