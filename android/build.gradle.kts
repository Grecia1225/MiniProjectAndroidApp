val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    configurations.all {
        resolutionStrategy {
            val lifecycleVersion = "2.7.0"
            force("androidx.lifecycle:lifecycle-common:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-runtime:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-runtime-ktx:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-viewmodel:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-viewmodel-ktx:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-livedata:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-livedata-core:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-process:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-service:$lifecycleVersion")
            force("androidx.lifecycle:lifecycle-viewmodel-savedstate:$lifecycleVersion")

            force("androidx.activity:activity:1.9.3")
            force("androidx.activity:activity-ktx:1.9.3")
            force("androidx.browser:browser:1.8.0")

            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
            force("androidx.core:core-viewtree:1.0.0")

            eachDependency {
                if (requested.group == "androidx.lifecycle") {
                    useVersion(lifecycleVersion)
                }
                if (requested.group == "androidx.activity") {
                    useVersion("1.9.3")
                }
                if (requested.group == "androidx.browser") {
                    useVersion("1.8.0")
                }
                if (requested.group == "androidx.core" && (requested.name == "core" || requested.name == "core-ktx")) {
                    useVersion("1.13.1")
                }
            }
        }
    }

    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }

        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}