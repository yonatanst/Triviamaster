// android/build.gradle (Project-level)
// Paste this whole file, then edit only versions if Android Studio asks.

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Google Services Gradle plugin (needed for google-services.json)
        classpath 'com.android.tools.build:gradle:8.3.2'
        classpath 'com.google.gms:google-services:4.4.2'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// For newer Gradle, you may see pluginManagement {} at top instead of buildscript.
// That is OK — keep pluginManagement, and ensure the google-services classpath is here.

rootProject.buildDir = "build"
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
