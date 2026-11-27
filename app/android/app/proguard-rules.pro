# ML Kit text recognition: only the Latin model is bundled. The other scripts are
# referenced by the plugin but absent, which would make the release build (R8) fail.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
