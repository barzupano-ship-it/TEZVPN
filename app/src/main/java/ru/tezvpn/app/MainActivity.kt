package ru.tezvpn.app

import android.app.Activity
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.runtime.Composable
import ru.tezvpn.app.ui.ShopViewModel
import ru.tezvpn.app.ui.TezAppUi
import ru.tezvpn.app.ui.TezTheme

class MainActivity : ComponentActivity() {
    private val vm: ShopViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            TezTheme {
                AppRoot(vm)
            }
        }
    }

    @Composable
    private fun AppRoot(vm: ShopViewModel) {
        val pickFile = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri: Uri? ->
            if (uri != null) vm.uploadReceipt(uri)
        }
        val vpnPerm = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { res ->
            if (res.resultCode == Activity.RESULT_OK) vm.connectAfterPermission()
        }
        TezAppUi(
            vm = vm,
            onPickReceipt = { pickFile.launch("*/*") },
            onPower = {
                if (vm.vpn.isUp()) {
                    vm.toggleVpn()
                } else {
                    val prepare = vm.vpn.prepareIntent(this)
                    if (prepare != null) vpnPerm.launch(prepare)
                    else vm.toggleVpn()
                }
            },
        )
    }
}
