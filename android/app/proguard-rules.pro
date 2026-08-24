# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core and Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Java & Jackson & XML Warnings Suppression
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn java.beans.**
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry
-dontwarn org.w3c.dom.**
-dontwarn com.fasterxml.jackson.**
-dontwarn javax.annotation.**
-dontwarn javax.xml.bind.**
-dontwarn javax.xml.**
