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

// Minecraft 26.3 is unobfuscated; generate empty identity mappings jar if missing
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

    // Quilt Loader & required runtime libraries (ASM 9.10.1 for Java 25 / MC 26.3)
    "modImplementation"("org.quiltmc:quilt-loader:${project.property("quilt_loader_version")}")
    "runtimeOnly"("org.ow2.asm:asm:9.10.1")
    "runtimeOnly"("org.ow2.asm:asm-analysis:9.10.1")
    "runtimeOnly"("org.ow2.asm:asm-commons:9.10.1")
    "runtimeOnly"("org.ow2.asm:asm-tree:9.10.1")
    "runtimeOnly"("org.ow2.asm:asm-util:9.10.1")
    "runtimeOnly"("org.quiltmc:quilt-json5:1.0.4+final")
    "runtimeOnly"("org.quiltmc:quilt-config:1.3.3")
    "runtimeOnly"("net.fabricmc:sponge-mixin:0.17.4+mixin.0.8.7")

    // Shader stack: Sodium + Sodium Extra + Iris + FerriteCore (Memory Optimization) + Litematica & MaLiLib
    clientMods("maven.modrinth:sodium:${project.property("sodium_version")}")
    clientMods("maven.modrinth:sodium-extra:${project.property("sodium_extra_version")}")
    clientMods("maven.modrinth:iris:${project.property("iris_version")}")
    clientMods("maven.modrinth:ferrite-core:${project.property("ferrite_core_version")}")
    clientMods("maven.modrinth:malilib:${project.property("malilib_version")}")
    clientMods("maven.modrinth:litematica:${project.property("litematica_version")}")

    "modImplementation"("maven.modrinth:sodium:${project.property("sodium_version")}")
    "modRuntimeOnly"("maven.modrinth:sodium-extra:${project.property("sodium_extra_version")}")
    "modRuntimeOnly"("maven.modrinth:iris:${project.property("iris_version")}")
    "modRuntimeOnly"("maven.modrinth:ferrite-core:${project.property("ferrite_core_version")}")
}

fun isMalilibUnpatched(file: File): Boolean {
    if (!file.exists()) return false
    return runCatching {
        ZipFile(file).use { zip ->
            val entry = zip.getEntry("mixins.malilib.json") ?: return false
            zip.getInputStream(entry).bufferedReader().use { it.readText() }.contains("test.MixinSharedConstants")
        }
    }.getOrDefault(false)
}

fun patchMalilibJar(src: File, dest: File) {
    val tempFile = File(dest.parentFile, "${dest.name}.tmp")
    ZipFile(src).use { zip ->
        ZipOutputStream(tempFile.outputStream()).use { zos ->
            for (entry in zip.entries().asSequence()) {
                zos.putNextEntry(ZipEntry(entry.name))
                if (entry.name == "mixins.malilib.json") {
                    val content = zip.getInputStream(entry).bufferedReader().use { it.readText() }
                    val patched = content.replace(Regex(",\\r?\\n\\s*\"test\\.MixinSharedConstants\""), "")
                    zos.write(patched.toByteArray(Charsets.UTF_8))
                } else {
                    zip.getInputStream(entry).use { it.copyTo(zos) }
                }
                zos.closeEntry()
            }
        }
    }
    if (dest.exists()) {
        dest.delete()
    }
    tempFile.renameTo(dest)
}

fun isLitematicaUnpatched(file: File): Boolean {
    if (!file.exists()) return false
    return runCatching {
        ZipFile(file).use { zip ->
            val entry = zip.getEntry("fi/dy/masa/litematica/render/schematic/WorldRendererSchematic.class") ?: return false
            val bytes = zip.getInputStream(entry).use { it.readBytes() }
            var hasLinearInSampler = false
            ClassReader(bytes).accept(object : ClassVisitor(Opcodes.ASM9) {
                override fun visitMethod(access: Int, name: String, descriptor: String, signature: String?, exceptions: Array<out String>?): MethodVisitor? {
                    if (name == "getGpuSampler") {
                        return object : MethodVisitor(Opcodes.ASM9) {
                            override fun visitFieldInsn(opcode: Int, owner: String, fieldName: String, fieldDescriptor: String) {
                                if (opcode == Opcodes.GETSTATIC && owner == "com/mojang/renderpearl/api/textures/FilterMode" && fieldName == "LINEAR") {
                                    hasLinearInSampler = true
                                }
                            }
                        }
                    }
                    return null
                }
            }, 0)
            hasLinearInSampler
        }
    }.getOrDefault(false)
}

fun patchLitematicaJar(src: File, dest: File) {
    val tempFile = File(dest.parentFile, "${dest.name}.tmp")
    ZipFile(src).use { zip ->
        ZipOutputStream(tempFile.outputStream()).use { zos ->
            for (entry in zip.entries().asSequence()) {
                zos.putNextEntry(ZipEntry(entry.name))
                if (entry.name == "fi/dy/masa/litematica/render/schematic/WorldRendererSchematic.class") {
                    val bytes = zip.getInputStream(entry).use { it.readBytes() }
                    val reader = ClassReader(bytes)
                    val writer = ClassWriter(reader, 0)
                    val cv = object : ClassVisitor(Opcodes.ASM9, writer) {
                        override fun visitMethod(access: Int, name: String, descriptor: String, signature: String?, exceptions: Array<out String>?): MethodVisitor {
                            val mv = super.visitMethod(access, name, descriptor, signature, exceptions)
                            if (name == "getGpuSampler") {
                                return object : MethodVisitor(Opcodes.ASM9, mv) {
                                    override fun visitFieldInsn(opcode: Int, owner: String, fieldName: String, fieldDescriptor: String) {
                                        if (opcode == Opcodes.GETSTATIC && owner == "com/mojang/renderpearl/api/textures/FilterMode" && fieldName == "LINEAR") {
                                            super.visitFieldInsn(opcode, owner, "NEAREST", fieldDescriptor)
                                        } else {
                                            super.visitFieldInsn(opcode, owner, fieldName, fieldDescriptor)
                                        }
                                    }
                                }
                            }
                            return mv
                        }
                    }
                    reader.accept(cv, 0)
                    zos.write(writer.toByteArray())
                } else {
                    zip.getInputStream(entry).use { it.copyTo(zos) }
                }
                zos.closeEntry()
            }
        }
    }
    if (dest.exists()) {
        dest.delete()
    }
    tempFile.renameTo(dest)
}

loom.runs.named("client") {
    configName = "Minecraft Client"
    runDir = "run/client"
    vmArg("-Xmx6G")
    vmArg("-XX:+UseG1GC")
}

val deployClientMods = tasks.register("deployClientMods") {
    group = "loom"
    description = "Deploys client runtime mods into run/client/mods."
    doLast {
        val modsDir = file("run/client/mods")
        modsDir.mkdirs()
        clientMods.resolvedConfiguration.resolvedArtifacts.forEach { artifact ->
            val dest = file("run/client/mods/${artifact.file.name}")
            val isMalilib = artifact.file.name.contains("malilib")
            val isLitematica = artifact.file.name.contains("litematica")
            val needsDeploy = !dest.exists() ||
                (isMalilib && isMalilibUnpatched(dest)) ||
                (isLitematica && isLitematicaUnpatched(dest))
            if (needsDeploy) {
                if (isMalilib) {
                    patchMalilibJar(artifact.file, dest)
                    val quiltCache = file("run/client/.cache/quilt_loader")
                    if (quiltCache.exists()) {
                        quiltCache.deleteRecursively()
                    }
                    println("✓ Deployed & patched mod -> ${dest.name} (removed test mixin)")
                } else if (isLitematica) {
                    patchLitematicaJar(artifact.file, dest)
                    val quiltCache = file("run/client/.cache/quilt_loader")
                    if (quiltCache.exists()) {
                        quiltCache.deleteRecursively()
                    }
                    println("✓ Deployed & patched mod -> ${dest.name} (enforced NEAREST texture filter)")
                } else {
                    artifact.file.copyTo(dest, overwrite = true)
                    println("✓ Deployed mod -> ${dest.name}")
                }
            }
        }
    }
}

tasks.named("runClient") {
    group = "loom"
    description = "Runs Minecraft Client with Quilt, Iris, Sodium, Sodium Extra, Litematica, and local Super Duper Vanilla shaderpack."
    dependsOn(deployClientMods)

    doFirst {
        // Link shaderpack
        val shaderpacksDir = file("run/client/shaderpacks")
        shaderpacksDir.mkdirs()
        val target = file("run/client/shaderpacks/Super-Duper-Vanilla")
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
