# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# photo_manager
-keep class com.fluttercandies.photo_manager.** { *; }

# local_auth (biometrics)
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# home_widget
-keep class es.antonborri.home_widget.** { *; }

# video_player (ExoPlayer)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# shared_preferences
-keep class androidx.datastore.** { *; }

# Google Fonts — font assets
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin serialization / reflection
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-dontwarn kotlin.**
-keep class kotlin.** { *; }

# Prevent stripping of app classes used via reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
