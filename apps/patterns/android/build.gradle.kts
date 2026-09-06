allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Plugins publish their own compileSdk, and some are behind what their own
// transitive dependencies now require - file_picker pulls in
// flutter_plugin_android_lifecycle, which insists on API 36. Raising it here
// rather than waiting for each plugin to catch up.
//
// This changes nothing about which devices the app runs on: minSdk governs
// that, and it is untouched.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { android ->
            when (android) {
                is com.android.build.gradle.BaseExtension ->
                    android.compileSdkVersion(36)
                else -> Unit
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
