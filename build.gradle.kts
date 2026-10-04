import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream
import org.objectweb.asm.ClassReader
import org.objectweb.asm.ClassVisitor
import org.objectweb.asm.ClassWriter
import org.objectweb.asm.MethodVisitor
import org.objectweb.asm.Opcodes

plugins {
    java
    id("fabric-loom") version "1.18.2"
}

repositories {
    mavenCentral()
    maven("https://maven.quiltmc.org/repository/release")
    maven("https://maven.fabricmc.net/")
    maven("https://api.modrinth.com/maven")
}

val loom = extensions.getByType<net.fabricmc.loom.api.LoomGradleExtensionAPI>()
loom.noIntermediateMappings()

// Minecraft 26.2 is unobfuscated; generate empty identity mappings jar if missing
val identityMappingsJar = layout.projectDirectory.file("gradle/identity-mappings.jar").asFile
if (!identityMappingsJar.exists()) {
    identityMappingsJar.parentFile.mkdirs()
    ZipOutputStream(identityMappingsJar.outputStream()).use { zos ->
        zos.putNextEntry(ZipEntry("mappings/mappings.tiny"))
        zos.write("tiny\t2\t0\tofficial\tnamed\n".toByteArray(Charsets.UTF_8))
        zos.closeEntry()
    }
}

// Configuration for runtime mods to be deployed to run/client/mods
val clientMods by configurations.creating {
    isCanBeResolved = true
    isCanBeConsumed = false
}

dependencies {
    "minecraft"("com.mojang:minecraft:${project.property("minecraft_version")}")
    "mappings"(files(identityMappingsJar))

    // Quilt Loader & required runtime libraries (ASM 9.10.1 for Java 25 / MC 26.2)
    "modImplementation"("org.quiltmc:quilt-loader:${project.property("quilt_loader_version")}")
    "runtimeOnly"("org.ow2.asm:asm:9.10.1")
    "runtimeOnly"("org.ow2.asm:asm-analysis:9.10.1")
    "runtimeOnly"("org.ow2.asm:asm-commons:9.10.1")
    "runtimeOnly"("org.ow2.asm:asm-tree:9.10.1")
    "runtimeOnly"("org.ow2.asm:asm-util:9.10.1")
    "runtimeOnly"("org.quiltmc:quilt-json5:1.0.4+final")
    "runtimeOnly"("org.quiltmc:quilt-config:1.3.3")
    "runtimeOnly"("net.fabricmc:sponge-mixin:0.17.4+mixin.0.8.7")

    // Shader stack: Sodium + Sodium Extra + Iris + FerriteCore (Memory Optimization) + Litematica & MaLiLib + Spark + Fabric API + GFX Debuggers + Voxy
    clientMods("maven.modrinth:sodium:${project.property("sodium_version")}")
    clientMods("maven.modrinth:sodium-extra:${project.property("sodium_extra_version")}")
    clientMods("maven.modrinth:iris:${project.property("iris_version")}")
    clientMods("maven.modrinth:ferrite-core:${project.property("ferrite_core_version")}")
    clientMods("maven.modrinth:malilib:${project.property("malilib_version")}")
    clientMods("maven.modrinth:litematica:${project.property("litematica_version")}")
    clientMods("maven.modrinth:spark:${project.property("spark_version")}")
    clientMods("maven.modrinth:fabric-api:${project.property("fabric_api_version")}")
    clientMods("maven.modrinth:gfx-debuggers:${project.property("gfx_debuggers_version")}")
    clientMods(files("libs/voxy-${project.property("voxy_version")}.jar"))

    "modImplementation"("maven.modrinth:sodium:${project.property("sodium_version")}")
    "modRuntimeOnly"("maven.modrinth:sodium-extra:${project.property("sodium_extra_version")}")
    "modRuntimeOnly"("maven.modrinth:iris:${project.property("iris_version")}")
    "modRuntimeOnly"("maven.modrinth:ferrite-core:${project.property("ferrite_core_version")}")
    "modRuntimeOnly"("maven.modrinth:spark:${project.property("spark_version")}")
    "modRuntimeOnly"("maven.modrinth:fabric-api:${project.property("fabric_api_version")}")
    "modRuntimeOnly"("maven.modrinth:gfx-debuggers:${project.property("gfx_debuggers_version")}")
    "modRuntimeOnly"(files("libs/voxy-${project.property("voxy_version")}.jar"))
}

loom.runs.named("client") {
    configName = "Minecraft Client"
    runDir = "run/client"
    vmArg("-Xmx6G")
    vmArg("-XX:+UseG1GC")
    vmArg("-javaagent:${file("gradle/dev-runtime-agent.jar").absolutePath}")
    vmArg("-Ddebugger=skip")
}

val deployClientMods = tasks.register("deployClientMods") {
    group = "loom"
    description = "Deploys client runtime mods into run/client/mods."
    doLast {
        val modsDir = file("run/client/mods")
        modsDir.mkdirs()
        val deployedNames = mutableSetOf<String>()
        clientMods.resolve().forEach { jarFile ->
            val dest = file("run/client/mods/${jarFile.name}")
            deployedNames.add(jarFile.name)
            jarFile.copyTo(dest, overwrite = true)
            println("✓ Deployed mod -> ${dest.name}")
        }
        modsDir.listFiles()?.forEach { f ->
            if (f.isFile && !deployedNames.contains(f.name)) {
                f.delete()
                println("✓ Cleaned stale mod -> ${f.name}")
            }
        }
    }
}

tasks.named<JavaExec>("runClient") {
    group = "loom"
    description = "Runs Minecraft Client with Quilt, Iris, Sodium, Sodium Extra, Voxy, Litematica, Spark, GFX Debuggers, and local HyperDuper Vanilla shaderpack."
    dependsOn(deployClientMods)
    jvmArgs("-javaagent:${file("gradle/dev-runtime-agent.jar").absolutePath}")
    systemProperty("debugger", System.getProperty("debugger", "skip"))

    doFirst {
        // Link shaderpack
        val shaderpacksDir = file("run/client/shaderpacks")
        shaderpacksDir.mkdirs()
        val target = file("run/client/shaderpacks/HyperDuper-Vanilla")
        if (!target.exists()) {
            runCatching {
                Files.createSymbolicLink(target.toPath(), rootDir.toPath())
                println("✓ Linked shaderpack -> ${target.absolutePath}")
            }.onFailure {
                println("Note: Symlink skipped (${it.message})")
            }
        }
    }
}
