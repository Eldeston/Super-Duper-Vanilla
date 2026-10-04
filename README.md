# HyperDuper Vanilla 🌟 (v1.0.0)

[![License: Custom](https://img.shields.io/badge/License-FlameRender%20Studios-blue.svg)](LICENSE)
[![Version: v1.0.0](https://img.shields.io/badge/Version-v1.0.0-success.svg)](https://github.com/porkyoot/HyperDuper-Vanilla/releases)
[![Author: @porkyoot](https://img.shields.io/badge/Author-%40porkyoot%20(Étoile)-orange.svg)](https://github.com/porkyoot)
[![Vibecoded with AI](https://img.shields.io/badge/Crafted%20with-AI%20Vibecoding-7928ca.svg)](#ai-vibecoding-journey)
[![Target: Iris & Minecraft](https://img.shields.io/badge/Minecraft-1.18.2%20--%2026.x%20%2F%20Iris-green.svg)](#version-compatibility)

> **HyperDuper Vanilla** is created and maintained by **[@porkyoot](https://github.com/porkyoot) (Étoile)**.
> 
> It is an independent, extensive overhaul and fork of [**Super Duper Vanilla**](https://github.com/Eldeston/Super-Duper-Vanilla) (originally created by [@Eldeston](https://github.com/Eldeston) and presented by **FlameRender Studios**).
> 
> Starting from the foundation of Super Duper Vanilla, Étoile completely reimagined and evolved the pack into their own creation through intensive **AI vibecoding**—introducing dynamic multi-day weather engines, hyper-optimized crepuscular godrays, procedural meteor showers, a gravitational lensing black hole in The End, Voxy LOD integrations, and an intuitive Sodium-style didactic configuration system.

---

## 🎬 Official Trailer & Showcase

[![HyperDuper Vanilla Trailer](https://img.youtube.com/vi/2VPc-Q5AKDM/maxresdefault.jpg)](https://www.youtube.com/watch?v=2VPc-Q5AKDM "Watch the HyperDuper Vanilla Trailer")

> 📺 **Watch the Trailer on YouTube**: [https://youtu.be/2VPc-Q5AKDM](https://youtu.be/2VPc-Q5AKDM)

---

## 🤖 The AI Vibecoding Journey

> [!NOTE]
> **Crafted with Frontier Agentic AI**: HyperDuper Vanilla was built by **Étoile (@porkyoot)** leveraging heavy AI pair-programming and vibecoding workflows (collaborating with frontier coding agents like Google DeepMind Antigravity, Gemini, and Claude).

Through rapid AI-assisted iteration, complex shader algorithms, numerical approximations, and large-scale architectural refactors were designed, tested, and fine-tuned:
* **High-Velocity Mathematics**: Translating optical physics into GLSL—such as affine-stepped cone-culled raymarching for crepuscular rays, $C^1$ Hermite shadow smoothing, and Schwarzschild-inspired accretion disk light deflection.
* **Continuous Quality Assurance**: Every line of GLSL and python tooling passes an automated **Continuous Quality Gate** (`python3 scripts/quality_gate.py`) verifying compilation through `glslangValidator`, inclusion resolution, McCabe cyclomatic complexity, and canonical i18n key coverage.
* **Freedom to Tinker**: This project is provided on an **"AS IS"** basis. You are warmly encouraged to fork this repository, explore the code, and make it your own!

---

## ✨ Extensive Feature Showcase

HyperDuper Vanilla v1.0.0 brings an extensive suite of new features, visual enhancements, and architectural overhauls:

### 1. 🌌 Celestial & Atmospheric Wonders
* **Hyper-Optimized Crepuscular Godrays**:
  * Real-time sunlight and moonlight volumetric shafts streaming through terrain, trees, water, and clouds.
  * **Dual-Path Distance-Adaptive Raymarching**: Dynamically adjusts sampling density near the sun, **doubling FPS when looking directly into the sun** with zero visual loss.
  * **Water Transmission**: Sunbeams realistically penetrate translucent ocean surfaces and stained glass.
  * **Underground Occlusion**: Strict height and light checks prevent atmospheric light leaks into caves and deep underground structures.
* **Procedural Dynamic Meteor Showers**:
  * Shooting stars streak across night skies with glowing leading pixel heads, ionization trails, and soft fade decays.
  * **Customizable Activity**: Choose between constant background meteors or dynamic waxing/waning shower waves with configurable speed, rarity, and tail length.
  * **6 Gemstone Color Profiles**: Electric Blue, Cosmic Violet, Emerald Green, Amber Gold, Diamond White, and Prismatic (each meteor receives a unique randomized gemstone hue).
* **Volumetric Northern Lights (Aurora Borealis)**:
  * Multi-layered dancing auroral curtains featuring altitude-based color gradients (pink tops, emerald centers, electric blue skirts) triggered in cold and snowy biomes.
* **Procedural Minecraft-Style Milky Way & Stars**:
  * Stylized galactic dust ribbon arching across the night sky, peppered with twinkling procedural stars.
  * **Star Rotation Settings**: Switch between aligned square pixel grids or organic rotated star fields.
* **Double Rainbows & Rainsquares**:
  * Procedural primary and secondary rainbow arches appearing opposite celestial light sources during light rain.
  * Full terrain shadow and block occlusion prevents rainbows from rendering indoors or through mountains.
* **Story Mode Clouds & Cirrus Altitude Layer**:
  * Vertical fade transitions inspired by Minecraft: Story Mode with customizable cloud heights and faint cirrus layers.
* **Continuous Celestial Roundness**:
  * Smooth continuous slider transitioning celestial bodies from authentic retro square pixels to circular discs, automatically propagated to reflections and flares.

---

### 2. 🕳️ The End Dimension Overhaul
* **Cosmic Gravitational Lensing Black Hole**:
  * The End's central sky is dominated by a majestic black hole featuring spiral accretion disk texturing and gravitational light deformation.
  * **Directional Global Illumination**: The accretion disk casts permanent directional lighting and shadows across the End islands.
* **Cosmic End Flashes**:
  * Dynamic sky flashes illuminate the void with synchronized directional shadows, atmospheric burst auras, and lens flares.
* **Ender Dragon Boss Fog**:
  * Atmospheric purple boss fog automatically descends upon and blankets the central island during the Ender Dragon fight.
* **Volumetric Aether Curtains**:
  * Shimmering atmospheric curtains adding depth and mystery to the void sky.

---

### 3. 🌧️ Dynamic Weather & Environmental Fog
* **Procedural Multi-Day Weather & Overcast**:
  * A continuous weather clock smoothly transitions the sky between crystal-clear days, moody overcast fronts, and stormy skies.
  * **Sun Showers**: Tuned rain overcast allows the sun and rainbows to break through during light precipitation.
  * **Above-Cloud Rain Cutoff**: Rain particles and weather fog smoothly fade out when flying above the cloud layer.
* **Dynamic Biome Humidity Fog**:
  * Ground mist dynamically thickens based on biome moisture—rivers, swamps, and rainforests develop dense morning fog, while arid deserts remain clear.
* **Pale Garden Atmospheric Mist**:
  * Custom light-gray eerie atmospheric mist tailored specifically for the Pale Garden biome and its canopy.
* **Creaking Eye Bloom**:
  * Creaking eyes cast vivid emissive glow and bloom through dark forests at night.

---

### 4. ⚡ Storm & Procedural Lightning
* **Multi-Tiered Lightning Engine**:
  * Realistic cloud-to-ground lightning bolts paired with dynamic cloud-to-cloud intra-cloud flashes.
* **Epilepsy & Sensory Safety**:
  * Built-in flash dampeners to reduce sudden high-contrast brightness shifts for light-sensitive players.
* **Customizable Bolt Colors**:
  * Personalize storm bolts with customizable RGB tinting options.

---

### 5. 🌊 Water Shading, Wave Physics & Materials
* **Multiple Water Aesthetic Styles**:
  * Toggle between **Classic**, **Modern**, and **Stylized SDGP** water rendering presets.
* **Depth-Based Wave Physics**:
  * Dynamic wave attenuation in shallow shorelines with natural foam reduction near land edges.
* **Refined Water Opacity & Subsurface Scattering (SSS)**:
  * Natural color absorption, water albedo tuning, and exclusion of underwater flora from false subsurface glow.
* **Targeted Block Outline**:
  * Polished selection box with vanilla inverted color blending and customizable outline thickness.

---

### 6. 🏔️ Level-Of-Detail (LOD) & Engine Mod Compatibility
* **Full Voxy LOD Integration**:
  * Custom Uniform Buffer Object (UBO) alignments, PBR material lookups, view positioning, and border fog blending for distant Voxy terrain chunks.
  * Dual depth support accommodating both OpenGL standard `[-1, 1]` NDC and `[0, 1]` zero-to-one depth pipelines.
  * Translucent depth texture support for modded distant oceans and water bodies.
* **Distant Horizons Compatibility**:
  * Harmonized albedo colors and luma multipliers for smooth transition zones between local and distant terrain.

---

### 7. 🎛️ Modern UI/UX & Didactic Tooltip System
* **Modular Dimensions Menu**:
  * Replaced legacy menus with a unified **Dimensions & Worlds** (`[DIMENSIONS]`) screen.
  * Pinned global settings (such as **Block Light Color** for torches, lanterns, campfires, lava) at the top.
  * Clean per-world configuration blocks ready for modded dimension expansion.
* **Flattened Materials & PBR Hierarchy**:
  * Direct access to POM, Water, Lava, and Sculk settings without buried sub-menus.
* **Sodium-Style Didactic Tooltips**:
  * Every single option features clear didactic indicators:
    * `§e[Visual]`: Explains exactly what changes on screen.
    * `[Performance]`: Color-coded performance cost (`§a[Very Low / Low]`, `§e[Moderate]`, `§c[Heavy / Very Heavy]`).
    * `§b[Tip]`: Practical advice, synergies, and recommended baselines.
* **Comprehensive i18n Localization**:
  * Full coverage across English (`en_US`), French (`fr_FR`), Simplified Chinese (`zh_CN`), Brazilian Portuguese (`pt_BR`), and Russian (`ru_RU`).

---

### 8. 🛠️ Developer Tooling & Quality Gate
* **Automated CI/CD Quality Gate** (`python3 scripts/quality_gate.py`):
  * Parallel GLSL compilation using `glslangValidator`.
  * i18n dictionary validator checking key coverage and syntax integrity.
  * McCabe cyclomatic complexity and file length gate.
  * Strict include reference resolver.
* **GPU Cost Profiler** (`scripts/profile_shaders.py`):
  * Static AST analyzer measuring texture lookups, transcendental math, and branch weights.
* **Live In-Game Hot-Reload** (`./gradlew runClient`):
  * Instant shader compilation on **`R`** keypress in a standalone Quilt/Iris runtime testbed.

---

## 🎮 Installation & Requirements

### Shader Loaders
* **Iris**: Recommended! Fully supported on Iris 1.6.10+ (Minecraft 1.18.2 through 1.21+ / 26.x).
* **OptiFine**: Legacy support; not actively tested.

### Supported Hardware & OS
* **Windows / Linux**: Fully supported on AMD, NVIDIA, and Intel (both dedicated and modern integrated GPUs).
* **Apple Silicon (macOS)**: Supported on M1/M2/M3/M4 via Iris.

### Installation Steps
1. Download `HyperDuper-Vanilla-v1.0.0.zip` from the [Releases](https://github.com/porkyoot/HyperDuper-Vanilla/releases) page.
2. Place the `.zip` archive into your Minecraft `.minecraft/shaderpacks/` folder.
3. In Minecraft (with Iris installed), navigate to **Options > Video Settings > Shader Packs...** and select **HyperDuper Vanilla**.

---

## 📜 Credits & License Attributions

HyperDuper Vanilla is developed by **[@porkyoot](https://github.com/porkyoot) (Étoile)** and is built upon the wonderful foundation of **Super Duper Vanilla**:
* **Original Creator of Super Duper Vanilla**: [@Eldeston](https://github.com/Eldeston) and **FlameRender Studios**.
* **Original Project**: [Super Duper Vanilla on GitHub](https://github.com/Eldeston/Super-Duper-Vanilla) | [CurseForge](https://www.curseforge.com/minecraft/customization/super-duper-vanilla-shaders) | [Modrinth](https://modrinth.com/shader/super-duper-vanilla)
* **Upstream Contributors**: [@null511](https://github.com/null511), [@steb-git](https://github.com/steb-git), and original community translators.
* **License**: Governed by the **FlameRender Studios License (v1.6)**. See [LICENSE](LICENSE) for the full license terms and copyright notices.