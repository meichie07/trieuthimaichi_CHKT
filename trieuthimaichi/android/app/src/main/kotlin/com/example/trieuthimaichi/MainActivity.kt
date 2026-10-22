package com.example.trieuthimaichi

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import androidx.annotation.NonNull
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.log10
import kotlin.math.sqrt

class MainActivity : FlutterFragmentActivity(), SensorEventListener {

    private val CHANNEL = "com.example.childmanagement/native"
    private lateinit var geofencingClient: GeofencingClient
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var latestGForce: Float = 0f

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        geofencingClient = LocationServices.getGeofencingClient(this)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        accelerometer?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "authenticateBiometric" -> {
                    authenticateBiometric(result)
                }
                "addGeofence" -> {
                    val lat = call.argument<Double>("latitude") ?: 0.0
                    val lng = call.argument<Double>("longitude") ?: 0.0
                    val radius = call.argument<Double>("radius")?.toFloat() ?: 200f
                    val key = call.argument<String>("key") ?: "safe_zone"
                    addGeofence(key, lat, lng, radius, result)
                }
                "getNoiseLevel" -> {
                    val decibel = measureDecibel()
                    result.success(decibel)
                }
                "getSensorMotion" -> {
                    result.success(latestGForce.toDouble())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun authenticateBiometric(result: MethodChannel.Result) {
        val executor = ContextCompat.getMainExecutor(this)
        val biometricPrompt = BiometricPrompt(this, executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(authResult: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(authResult)
                    result.success(true)
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    result.error("BIOMETRIC_ERROR", errString.toString(), null)
                }

                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    result.success(false)
                }
            })

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Xác thực Phụ huynh")
            .setSubtitle("Nhập vân tay hoặc khuôn mặt để tiếp tục")
            .setNegativeButtonText("Hủy")
            .build()

        biometricPrompt.authenticate(promptInfo)
    }

    @SuppressLint("MissingPermission")
    private fun addGeofence(
        key: String,
        latitude: Double,
        longitude: Double,
        radiusInMeters: Float,
        result: MethodChannel.Result
    ) {
        try {
            val geofence = Geofence.Builder()
                .setRequestId(key)
                .setCircularRegion(latitude, longitude, radiusInMeters)
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_EXIT or Geofence.GEOFENCE_TRANSITION_ENTER)
                .build()

            val request = GeofencingRequest.Builder()
                .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
                .addGeofence(geofence)
                .build()

            val intent = Intent(this, GeofenceBroadcastReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )

            geofencingClient.addGeofences(request, pendingIntent).addOnSuccessListener {
                result.success(true)
            }.addOnFailureListener { e ->
                result.error("GEOFENCE_ERROR", e.message, null)
            }
        } catch (e: Exception) {
            result.error("GEOFENCE_EXCEPTION", e.message, null)
        }
    }

    @SuppressLint("MissingPermission")
    private fun measureDecibel(): Double {
        return try {
            val sampleRate = 8000
            val channelConfig = AudioFormat.CHANNEL_IN_MONO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)

            if (minBufferSize <= 0) return 0.0

            val audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate, channelConfig, audioFormat, minBufferSize
            )
            val buffer = ShortArray(minBufferSize)
            audioRecord.startRecording()
            val readSize = audioRecord.read(buffer, 0, minBufferSize)
            audioRecord.stop()
            audioRecord.release()

            var sumSquare = 0.0
            for (i in 0 until readSize) {
                sumSquare += buffer[i] * buffer[i]
            }
            val amplitude = if (readSize > 0) sumSquare / readSize else 0.0
            if (amplitude > 0) 20 * log10(sqrt(amplitude) / 32767.0) + 90 else 0.0
        } catch (e: Exception) {
            0.0
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]
            val gForce = sqrt((x * x + y * y + z * z).toDouble()) / SensorManager.GRAVITY_EARTH
            latestGForce = gForce.toFloat()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
