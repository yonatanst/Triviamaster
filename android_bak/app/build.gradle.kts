// android/app/build.gradle (Module-level)
// Paste this entire file. Replace applicationId if you picked another package name.

plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
    id 'kotlin-android'
}

android {
    namespace 'com.triviamaster.app'
    compileSdk 34

    defaultConfig {
        applicationId 'com.triviamaster.app'
        minSdk 23
        targetSdk 34
        versionCode 1
        versionName '1.0.0'
        multiDexEnabled true
    }

    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            // debug-specific flags if needed
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = '17'
    }

    packagingOptions {
        resources {
            excludes += [
                'META-INF/AL2.0',
                'META-INF/LGPL2.1'
            ]
        }
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.4.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-firestore'
    implementation 'com.google.firebase:firebase-functions'

    implementation 'androidx.core:core-ktx:1.13.1'
    implementation 'androidx.appcompat:appcompat:1.7.0'
    implementation 'com.google.android.material:material:1.12.0'
    implementation 'androidx.activity:activity-ktx:1.9.2'
    implementation 'androidx.fragment:fragment-ktx:1.8.3'

    implementation 'com.google.android.gms:play-services-base:18.5.0'
    implementation 'androidx.multidex:multidex:2.0.1'
}

// NOTE:
// 1) Put your google-services.json at android/app/google-services.json
// 2) If Android Studio suggests a newer AGP or Kotlin version, accept its prompt; this file will still work.
// 3) If you chose a different package name, update both namespace + applicationId and re-download google-services.json for that ID.
