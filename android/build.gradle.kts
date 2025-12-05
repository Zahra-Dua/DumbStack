allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    // Fix for device_apps package namespace issue and compileSdk
    afterEvaluate {
        // Force all Android subprojects to use compileSdk 31+ (required for lStar attribute)
        project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.let { android ->
            val currentSdk = android.compileSdkVersion
            val currentSdkInt = if (currentSdk != null) {
                currentSdk.removePrefix("android-").toIntOrNull() ?: 0
            } else {
                0
            }
            
            if (currentSdkInt < 31) {
                // Use setCompileSdkVersion method with String
                try {
                    val method = android.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                    method.invoke(android, "31")
                    println("✅ Set compileSdk to 31 for ${project.name}")
                } catch (e: Exception) {
                    // Try with Int
                    try {
                        val method = android.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                        method.invoke(android, 31)
                        println("✅ Set compileSdk to 31 (Int) for ${project.name}")
                    } catch (e2: Exception) {
                        // Try direct property assignment with String
                        try {
                            @Suppress("DEPRECATION")
                            android.compileSdkVersion = "31"
                            println("✅ Set compileSdk to 31 (String) for ${project.name}")
                        } catch (e3: Exception) {
                            println("⚠️ Could not set compileSdk for ${project.name}: ${e3.message}")
                        }
                    }
                }
            }
        }
        
        if (project.name == "device_apps" || project.path.contains("device_apps")) {
            var namespace: String? = null
            
            try {
                // Try to get namespace from AndroidManifest.xml
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                
                if (manifestFile.exists()) {
                    val manifestContent = manifestFile.readText()
                    val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestContent)
                    if (packageMatch != null) {
                        namespace = packageMatch.groupValues[1]
                    }
                }
                
                // Fallback namespace if not found in manifest
                if (namespace == null) {
                    namespace = "fr.g123k.deviceapps"
                }
                
                // Configure android block
                project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.let { android ->
                    android.namespace = namespace
                    // Ensure compileSdk is at least 31
                    val currentSdk = android.compileSdkVersion
                    val currentSdkInt = if (currentSdk != null) {
                        currentSdk.removePrefix("android-").toIntOrNull() ?: 0
                    } else {
                        0
                    }
                    
                    if (currentSdkInt < 31) {
                        try {
                            val method = android.javaClass.getMethod("setCompileSdkVersion", String::class.java)
                            method.invoke(android, "31")
                        } catch (e: Exception) {
                            try {
                                val method = android.javaClass.getMethod("setCompileSdkVersion", Int::class.java)
                                method.invoke(android, 31)
                            } catch (e2: Exception) {
                                @Suppress("DEPRECATION")
                                android.compileSdkVersion = "31"
                            }
                        }
                    }
                    println("✅ Set namespace and compileSdk for ${project.name}: $namespace")
                }
            } catch (e: Exception) {
                println("⚠️ Could not set namespace for ${project.name}: ${e.message}")
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
