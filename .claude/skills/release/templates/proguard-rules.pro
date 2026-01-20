# ProGuard/R8 Rules for Flutter Apps
#
# INSTRUCTIONS:
# 1. Copy this file to android/app/proguard-rules.pro
# 2. Remove sections for packages you don't use
# 3. Add rules for any additional packages causing issues
#
# REFERENCE:
# https://developer.android.com/studio/build/shrink-code

# ============================================================
# FLUTTER CORE (Required)
# ============================================================

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ============================================================
# GOOGLE PLAY CORE (Common warnings source)
# ============================================================

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ============================================================
# JSON SERIALIZATION (Freezed, json_serializable)
# ============================================================

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Keep Gson classes if using
-keep class com.google.gson.** { *; }
-keepattributes EnclosingMethod

# ============================================================
# NETWORKING (Dio, Retrofit, OkHttp)
# ============================================================

# Retrofit
-keep class retrofit2.** { *; }
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations

# OkHttp
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# Okio
-keep class okio.** { *; }
-dontwarn okio.**

# ============================================================
# SUPABASE (if using supabase_flutter)
# ============================================================

-keep class io.supabase.** { *; }
-keep class com.github.supabase.** { *; }

# ============================================================
# FIREBASE (if using Firebase)
# ============================================================

# Firebase Core
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Firebase Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Firebase Analytics
-keep class com.google.android.gms.measurement.** { *; }

# ============================================================
# GOOGLE SIGN-IN (if using google_sign_in)
# ============================================================

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ============================================================
# DEBUG & CRASH REPORTING
# ============================================================

# Preserve line numbers for debugging crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# If keeping stack traces
-keep class * extends java.lang.Exception

# ============================================================
# ADDITIONAL RULES
# ============================================================

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ============================================================
# YOUR APP'S MODEL CLASSES
# ============================================================

# If R8 strips your Freezed/JSON models, add them here:
# -keep class com.yourpackage.data.models.** { *; }

# ============================================================
# TROUBLESHOOTING
# ============================================================

# If you get "Duplicate class" errors, try:
# -dontnote **

# If specific classes are being stripped, find them with:
# flutter build apk --release -v 2>&1 | grep "stripped"

# Then add: -keep class <full.class.name> { *; }
