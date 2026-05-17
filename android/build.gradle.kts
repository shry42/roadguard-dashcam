import java.io.File
import java.nio.file.Files

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ExFAT (external SSD) creates AppleDouble "._*" files in build/ and breaks Android tooling.
// Point project build/ at APFS via symlink so Flutter and Gradle share the same path.
fun isExfatVolume(dir: File): Boolean =
    try {
        Files.getFileStore(dir.toPath()).type().contains("exfat", ignoreCase = true)
    } catch (_: Exception) {
        false
    }

fun ensureApfsBuildSymlink(projectRoot: File) {
    val internalBuild = File(
        System.getProperty("user.home"),
        ".cache/roadguard_dashcam/build",
    )
    internalBuild.mkdirs()
    val projectBuild = File(projectRoot, "build")
    if (projectBuild.exists() && !Files.isSymbolicLink(projectBuild.toPath())) {
        projectBuild.deleteRecursively()
    }
    if (!Files.isSymbolicLink(projectBuild.toPath())) {
        Files.createSymbolicLink(projectBuild.toPath(), internalBuild.toPath())
    }
}

val projectRoot = rootProject.rootDir.parentFile!!
if (isExfatVolume(projectRoot)) {
    ensureApfsBuildSymlink(projectRoot)
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
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
