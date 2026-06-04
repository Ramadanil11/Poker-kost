package com.example.custom_card_core

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "poker_kost/audio"
    private var soundPool: SoundPool? = null
    private val soundIds = mutableMapOf<String, Int>()
    private var backsound: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playEffect" -> {
                        val name = call.argument<String>("name")
                        if (name != null) playEffect(name)
                        result.success(null)
                    }
                    "startBacksound" -> {
                        startBacksound()
                        result.success(null)
                    }
                    "stopBacksound" -> {
                        stopBacksound()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun pool(): SoundPool {
        soundPool?.let { return it }
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        return SoundPool.Builder()
            .setMaxStreams(4)
            .setAudioAttributes(attrs)
            .build()
            .also { soundPool = it }
    }

    private fun playEffect(name: String) {
        try {
            val soundId = soundIds.getOrPut(name) {
                assets.openFd("flutter_assets/sound/$name.mp3").use { fd ->
                    pool().load(fd, 1)
                }
            }
            pool().play(soundId, 1f, 1f, 1, 0, 1f)
        } catch (_: Exception) {
            // Placeholder or missing files should not break gameplay.
        }
    }

    private fun startBacksound() {
        if (backsound?.isPlaying == true) return
        try {
            backsound = MediaPlayer().apply {
                assets.openFd("flutter_assets/sound/backsound.mp3").use { fd ->
                    setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                }
                isLooping = true
                setVolume(0.42f, 0.42f)
                prepare()
                start()
            }
        } catch (_: Exception) {
            backsound = null
        }
    }

    private fun stopBacksound() {
        try {
            backsound?.stop()
            backsound?.release()
        } catch (_: Exception) {
        } finally {
            backsound = null
        }
    }

    override fun onDestroy() {
        stopBacksound()
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
