# MediaPipe specific rules
-keep class com.google.mediapipe.** { *; }
-keep class com.google.mediapipe.proto.** { *; }

# ML Kit Text Recognition rules
# This prevents R8 from complaining about scripts you AREN'T using (Devanagari, Japanese, etc.)
# while ensuring the core and Chinese ones remain intact.
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }

# General Google Play Services / ML Kit Keep Rules
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }