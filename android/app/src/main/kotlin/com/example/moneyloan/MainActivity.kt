package com.example.moneyloan

import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "money_loan/intents"
    private lateinit var methodChannel: MethodChannel
    private var pendingFilePath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cacheIncomingIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFilePath" -> {
                    result.success(pendingFilePath)
                    pendingFilePath = null
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        cacheIncomingIntent(intent, notifyFlutter = true)
    }

    private fun cacheIncomingIntent(intent: Intent?, notifyFlutter: Boolean = false) {
        val uri = extractFileUri(intent) ?: return
        val cachedPath = copyIncomingFile(uri) ?: return

        if (!cachedPath.endsWith(".mloan", ignoreCase = true)) {
            return
        }

        if (notifyFlutter && ::methodChannel.isInitialized) {
            methodChannel.invokeMethod("onIncomingFile", cachedPath)
            return
        }

        pendingFilePath = cachedPath
    }

    private fun extractFileUri(intent: Intent?): Uri? {
        if (intent == null) {
            return null
        }

        return when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
            }

            else -> null
        }
    }

    private fun copyIncomingFile(uri: Uri): String? {
        return try {
            val originalName = resolveFileName(uri)
            val safeName = if (originalName.endsWith(".mloan", ignoreCase = true)) {
                originalName
            } else {
                "$originalName.mloan"
            }

            val importDir = File(cacheDir, "incoming_updates")
            if (!importDir.exists()) {
                importDir.mkdirs()
            }

            val outputFile = File(importDir, safeName)
            contentResolver.openInputStream(uri)?.use { input ->
                outputFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            outputFile.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    private fun resolveFileName(uri: Uri): String {
        val fallback = "moneyloan_update.mloan"
        if (uri.scheme != "content") {
            return uri.lastPathSegment ?: fallback
        }

        val cursor: Cursor? = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            val nameColumn = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (it.moveToFirst() && nameColumn >= 0) {
                val rawName = it.getString(nameColumn)
                if (!rawName.isNullOrBlank()) {
                    return rawName
                }
            }
        }
        return fallback
    }
}

