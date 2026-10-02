# Flutter specific ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Drift / SQLite
-keep class * extends androidx.room.** { *; }
-dontwarn androidx.room.paging.**
-keep class net.sqlcipher.** { *; }

# SharedPreferences
-keep class android.content.** { *; }

# Keep Dart/Flutter serialization classes
-keep class com.zexano.** { *; }
-keep class com.example.zexano_sms.** { *; }

# Keep Gson/JSON serialization (if used by plugins)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
