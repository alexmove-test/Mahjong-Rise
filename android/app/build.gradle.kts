import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Онлайн-рейтинг: плагин нужен только когда есть конфиг Firebase.
val googleServicesFile = file("google-services.json")
if (googleServicesFile.exists()) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle(
        "Mahjong: google-services.json not found — release build continues without Firebase. " +
            "Add the file and run flutterfire configure to enable online rating.",
    )
}

data class AppVersion(val name: String, val code: Int)

fun shouldBumpBuildNumber(): Boolean {
    return gradle.startParameter.taskNames.any { raw ->
        val task = raw.substringAfterLast(':').lowercase()
        task.startsWith("assemble") || task.startsWith("bundle")
    }
}

fun resolveAndMaybeBumpVersion(): AppVersion {
    val pubspec = file("../../pubspec.yaml")
    val text = pubspec.readText()
    val regex = Regex("""version:\s*(\d+\.\d+\.\d+)(?:\+(\d+))?""")
    val match = regex.find(text) ?: error("version: not found in pubspec.yaml")
    val name = match.groupValues[1]
    val currentCode = match.groupValues[2].toIntOrNull() ?: 0
    val bump = shouldBumpBuildNumber()
    val code = if (bump) currentCode + 1 else currentCode.coerceAtLeast(1)

    if (bump) {
        pubspec.writeText(regex.replaceFirst(text, "version: $name+$code"))
        file("../../lib/app_version.dart").writeText(
            """
            |/// Сгенерировано при Android-сборке. Не править вручную.
            |const appVersionName = '$name';
            |const appBuildNumber = $code;
            |
            |String get appVersionLabel => 'v${'$'}appVersionName+${'$'}appBuildNumber';
            |
            """.trimMargin(),
        )
        println("Mahjong version -> $name+$code")
    }

    return AppVersion(name, code)
}

val appVersion = resolveAndMaybeBumpVersion()

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.rise.mahjong"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.rise.mahjong"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = appVersion.code
        versionName = appVersion.name
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "Mahjong: android/key.properties not found — release signed with debug key.",
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Стандартное имя app-release.* нужно Flutter для post-build проверки AAB.
// Версионированные копии складываем отдельно в outputs/named/.
val versionedArtifactBase = "mahjong-rise-v${appVersion.name}+${appVersion.code}"

tasks.register<Delete>("cleanStaleReleaseBundles") {
    delete(
        layout.buildDirectory.dir("outputs/bundle/release").map { dir ->
            dir.asFile.listFiles()?.filter { it.isFile && it.extension == "aab" } ?: emptyList()
        },
    )
}

tasks.register<Copy>("copyVersionedReleaseBundle") {
    val bundleFile = layout.buildDirectory.file("outputs/bundle/release/app-release.aab")
    from(bundleFile)
    into(layout.buildDirectory.dir("outputs/named"))
    rename { "$versionedArtifactBase-release.aab" }
    onlyIf { bundleFile.get().asFile.exists() }
}

tasks.register<Copy>("copyVersionedReleaseApk") {
    val apkFile = layout.buildDirectory.file("outputs/apk/release/app-release.apk")
    from(apkFile)
    into(layout.buildDirectory.dir("outputs/named"))
    rename { "$versionedArtifactBase-release.apk" }
    onlyIf { apkFile.get().asFile.exists() }
}

tasks.configureEach {
    if (name == "bundleRelease") {
        dependsOn("cleanStaleReleaseBundles")
        finalizedBy("copyVersionedReleaseBundle")
    }
    if (name == "assembleRelease") {
        finalizedBy("copyVersionedReleaseApk")
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // play-services-ads pulls work-runtime 2.7.0, which crashes on startup in release
    // with AGP 9 + R8 full mode (WorkDatabase initialization via androidx.startup).
    // https://github.com/googleads/googleads-mobile-flutter/issues/1444
    implementation("androidx.work:work-runtime:2.11.2")
}
