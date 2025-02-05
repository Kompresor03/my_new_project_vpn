package com.spydog.vpn

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.app.Activity
import android.util.Log
import id.laskarmedia.openvpn_flutter.OpenVPNFlutterPlugin

class MainActivity: FlutterActivity() {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == 24 && resultCode == Activity.RESULT_OK) {
            OpenVPNFlutterPlugin.connectWhileGranted(true)
            Log.d("SpyDogVPN", "VPN permission granted")
        } else {
            Log.d("SpyDogVPN", "VPN permission not granted: requestCode=$requestCode, resultCode=$resultCode")
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}