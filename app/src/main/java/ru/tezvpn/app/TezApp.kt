package ru.tezvpn.app

import android.app.Application

class TezApp : Application() {
    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    companion object {
        lateinit var instance: TezApp
            private set
    }
}
