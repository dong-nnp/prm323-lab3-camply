package com.example.prm393_lab03

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Process
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) == 0) return

        val metadata = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA).metaData
        val marker = File(filesDir, "evia-qa-crash-pid")
        if (metadata?.getBoolean("firebase_crashlytics_collection_enabled") == true) {
            runCatching { marker.writeText(Process.myPid().toString()) }
        }
    }
}
