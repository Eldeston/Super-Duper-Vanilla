# HyperDuper Vanilla 🌟

[![License: Custom](https://img.shields.io/badge/License-FlameRender%20Studios-blue.svg)](LICENSE)
[![Status: Experimental Fork](https://img.shields.io/badge/Status-Experimental%20Fork-ff69b4.svg)](#disclaimer--maintenance)
[![Vibecoded with AI](https://img.shields.io/badge/Crafted%20with-AI%20Vibecoding-7928ca.svg)](#ai-vibecoding-disclosure)
[![Target: Iris & Minecraft](https://img.shields.io/badge/Minecraft-26.2%20%2F%20Iris%201.6%2B-green.svg)](#version-compatibility)

> **HyperDuper Vanilla** is an experimental, performance-tuned community fork of [**Super Duper Vanilla**](https://github.com/Eldeston/Super-Duper-Vanilla) (originally created by [@Eldeston](https://github.com/Eldeston) and presented by **FlameRender Studios**).
> 
> It elevates the iconic aesthetic of the cancelled *Super Duper Graphics Pack* with modern atmospheric rendering, celestial wonders, intuitive UI/UX navigation with didactic Sodium-style tooltips, modular multi-dimension support, and high-performance optimizations.

---

## ⚠️ Disclaimer & Maintenance Notice

> [!IMPORTANT]
> **Provided "AS IS"**: This project is provided strictly on an **"AS IS"** basis, without warranties, guarantees, or conditions of any kind, either express or implied, including but not limited to stability, mod compatibility, or fitness for a particular purpose.
>
> **Maintenance May Not Be Active**: This is an exploratory, passion-driven fork. Development and maintenance may be sporadic, intermittent, or completely inactive. 
> 
> **You are free and encouraged to fork!** If you want to fix a bug, add a feature, or adapt this shaderpack into your own project, please feel free to fork this repository, borrow code, and make it your own.

---

## 🤖 AI Vibecoding Disclosure

> [!NOTE]
> **Heavy Use of AI Vibecoding**: HyperDuper Vanilla is developed with heavy use of **AI pair-programming and vibecoding** (leveraging frontier agentic AI coding assistants like Google DeepMind Antigravity / Gemini / Claude).
>
> What this means for you:
> * **Rapid Iteration**: Complex shader algorithms, math pipelines, and extensive refactors were drafted, iterated, and benchmarked collaboratively with AI.
> * **Experimental & Creative**: You'll find ambitious features like adaptive-step godrays, procedural meteor showers, dynamic overcast weather cycles, and full Voxy LOD integrations.
> * **Automated Quality Assured**: All shader code, GLSL compilation, AST complexity, and i18n localization keys are continuously validated through an automated CI/CD Quality Gate pipeline (`glslangValidator`, inclusion linters, and profiling tools).

---

## ✨ Features & What's New in HyperDuper Vanilla

### 1. Intuitive UI/UX & Didactic Sodium-Style Options
* **Modular Dimensions Menu**: Replaced the obscure "Configuration" menu with an intuitive **Dimensions & Worlds** (`[DIMENSIONS]`) screen.
  * **Common Settings on Top**: Global options affecting all worlds—such as **Block Light Color** (torches, lanterns, campfires, lava)—are pinned at the top.
  * **Easily Expandable**: Dimensions (Overworld, Nether, End) are listed cleanly below, making it effortless for developers to add new modded dimensions (e.g. Aether, Undergarden, Twilight Forest).
* **Flattened Materials & PBR Hierarchy**: Removed unnecessary middleman sub-menus; Water, Parallax (POM), Lava, and Sculk settings are now directly accessible with fewer clicks.
* **Balanced 2-Column Grid**: Fixed legacy layout bugs and paired every setting toggle directly beside its strength slider.
* **Sodium-Style Color-Coded Tooltips**: Every single setting features a didactic, beginner-friendly explanation:
  * `§e[Visual]`: Explains exactly what changes on your screen.
  * `[Performance]`: Color-coded performance indicator:
    * `§a[Performance: None / Very Low / Low]` (Minimal to zero FPS impact)
    * `§e[Performance: Moderate]` (Balanced GPU impact)
    * `§c[Performance: Heavy / Very Heavy]` (Demanding; recommended for dedicated GPUs)
  * `§b[Tip]`: Practical recommendations and synergies with other settings.

---

### 2. Celestial & Atmospheric Wonders
* **Crepuscular Atmospheric Godrays**:
  * Real-time sunlight and moonlight light shafts streaming through clouds, trees, water, and terrain.
  * **Adaptive Step Optimization**: Dynamically optimizes raymarching sample density near the sun, **doubling FPS when facing the sun** with zero visual loss.
  * **Water Transmission**: Allows sunbeams to penetrate translucent ocean depths and stained glass windows.
* **Procedural Dynamic Meteor Showers**:
  * Shooting stars streak across nighttime skies with glowing leading pixel heads, ionization tails, and fade trails.
  * Customizable shower rarity (nightly, periodic, or lunar cycle), shower rates, flight speeds, tail lengths, and activity modes (constant vs dynamic waxing/waning waves).
  * **6 Color Profiles**: Electric Blue, Cosmic Violet, Emerald Green, Amber Gold, Diamond White, and Prismatic (each meteor gets a unique randomized gemstone color).
* **Procedural Minecraft-Style Milky Way**:
  * Stylized galactic ribbon spanning the night sky with thousands of twinkling square stars and nebula dust clouds.
* **Volumetric Northern Lights (Aurora Borealis)**:
  * Dancing volumetric curtains transitioning from pink tops to emerald centers and electric blue bottoms in cold and snowy biomes.
* **Double Rainbows & Rainsquares**:
  * Procedural primary and secondary rainbow arches opposite celestial light during rain, following the Sun/Moon Roundness geometry.
* **Star Rotation Styles**:
  * Switch between aligned square grid stars or organic random star rotation angles.

---

### 3. Dynamic Environment & Dimensional Lighting
* **Procedural Weather & Overcast System**:
  * Multi-day weather clock with gradual overcast intensity transitions, moving smoothly from crystal clear blue skies to moody overcast storm fronts.
* **Dynamic Biome Humidity Fog**:
  * Links fog probability to dynamic weather moisture and biome humidity: swamps, rivers, and jungles develop thick atmospheric mist, while arid deserts stay clear.
* **Pale Garden Atmospheric Mist**:
  * Atmospheric light-gray mist tailored for the Pale Garden biome.
* **The End Black Hole Lighting & Dragon Boss Fog**:
  * Permanent directional light cast from the cosmic Black Hole accretion disk.
  * Atmospheric purple boss fog that envelops the central island during the Ender Dragon battle.
* **Hermite-Smoothed Shadow Transitions**:
  * Eliminates harsh shadow camera flips when celestial bodies cross the horizon using smooth $C^1$ Hermite fade curves.

---

### 4. Engine, Modding & Optimization Pipeline
* **Voxy LOD Integration**:
  * Full pipeline compatibility with the Voxy distant Level-of-Detail (LOD) terrain mod across Overworld, Nether, and End dimensions with custom UBO layouts, PBR material lookups, and atmospheric border blending.
* **Render Pass Pruning & Guarding**:
  * Conditional shader pass elimination (`program.<name>.enabled = false`) for inactive features (DOF, motion blur, bloom, SSAO).
  * Frustum bounding-box early-exit culling and backfacing normal rejection to skip redundant raymarches.
* **Built-In Profiling & Diagnostics Suite**:
  * Integrated static shader performance profiler (`scripts/profile_shaders.py`) to quantify GPU costs, texture lookups, and math ops.
  * Spark profiler, RenderDoc, and NVIDIA Nsight launch tasks for frame capture and memory analysis.

---

## 🛠️ Developer & Contributor Guide

We want HyperDuper Vanilla to be as **welcoming, transparent, and easy to modify** as possible for other shader developers, modders, and curious tinkerers!

### Repository Structure
```
HyperDuper-Vanilla/
├── shaders/
│   ├── shaders.properties     # Master menu layout, pass toggles, profiles, and uniforms
│   ├── dimension.properties   # Dimension routing (* -> world0, nether -> world-1, end -> world1)
│   ├── lang/                  # i18n translations (en_US.lang is the canonical master)
│   ├── lib/                   # Shared shader libraries (atmospherics, lighting, PBR, etc.)
│   ├── main/                  # Core G-buffer, deferred, composite, and final passes
│   ├── world0/                # Overworld dimension overrides & color definitions
│   ├── world-1/               # Nether dimension overrides
│   └── world1/                # The End dimension overrides
├── scripts/
│   ├── quality_gate.py        # Automated CI/CD validation pipeline
│   ├── lint.py                # glslangValidator GLSL shader compiler linter
│   ├── profile_shaders.py     # Static performance and GPU cost analyzer
│   └── build.py               # Release packaging script
├── Taskfile.yml               # Task runner targets
└── build.gradle.kts           # Loom / Quilt test environment configuration
```

### Adding a New Dimension
Adding custom dimensions (e.g. Aether, Undergarden, Twilight Forest) is straightforward:
1. **Assign the dimension** in `shaders/dimension.properties`:
   ```properties
   dimension.world2 = aether:the_aether
   ```
2. **Create the dimension folder** `shaders/world2/world.glsl` defining dimension properties (`WORLD_ID 2`, light colors, fog density).
3. **Expose the menu** in `shaders/shaders.properties` under `screen.DIMENSIONS`:
   ```properties
   screen.DIMENSIONS = \
       [BLOCK_LIGHT_COLOR] <empty> \
       <empty> <empty> \
       [OVERWORLD_SETTINGS] [NETHER_SETTINGS] \
       [END_SETTINGS] [AETHER_SETTINGS]
   ```
4. **Add localized labels** in `shaders/lang/en_US.lang`.

### Running Locally with Hot-Reload
You can launch an isolated testing instance with Quilt, Sodium, Iris, and Voxy pre-configured:
```bash
./gradlew runClient
```
* **Instant Hot-Reload**: Press **`R`** in-game at any time to recompile and reload all shader modifications live without restarting Minecraft!
* **F3 Overlay**: Displays real-time pass execution and framebuffer timings.

### Running Quality & Performance Gates
Before submitting a pull request, ensure your code passes our quality gate:
```bash
# Run the complete multi-stage quality gate:
python3 scripts/quality_gate.py

# Benchmark GPU performance metrics and texture lookups:
python3 scripts/profile_shaders.py
```

### How to Contribute
* Pull requests are warmly welcomed! Whether you are writing handcrafted GLSL, refining translations, or vibecoding new features with AI assistants, we would love to see your ideas.
* Please keep code readable, document your changes, and make sure `python3 scripts/quality_gate.py` passes cleanly.
* See [**CONTRIBUTION.md**](CONTRIBUTION.md) and [**DOCUMENTATION.md**](DOCUMENTATION.md) for detailed coding conventions and pipeline architecture.

---

## 🎮 Compatibility & Requirements

### Shader Loaders
* **Iris**: Recommended! Fully supported on Iris 1.6.10+ (Minecraft 1.18.2+ through 1.21+ / 26.x).
* **OptiFine**: Legacy support only; not actively maintained.

### Supported Operating Systems & Hardware
* **Windows / Linux**: Fully supported on AMD, NVIDIA, and Intel (dedicated & modern integrated GPUs).
* **Apple Silicon (macOS)**: Supported on M1/M2/M3/M4 via Iris.

---

## 📜 Credits & Attributions

HyperDuper Vanilla is built upon the wonderful foundation of **Super Duper Vanilla**:
* **Original Creator**: [@Eldeston](https://github.com/Eldeston) and **FlameRender Studios**.
* **Original Project**: [Super Duper Vanilla on GitHub](https://github.com/Eldeston/Super-Duper-Vanilla) | [CurseForge](https://www.curseforge.com/minecraft/customization/super-duper-vanilla-shaders) | [Modrinth](https://modrinth.com/shader/super-duper-vanilla)
* **Contributors**: [@null511](https://github.com/null511), [@steb-git](https://github.com/steb-git), and the SDV translator community.
* **License**: Governed by the original FlameRender Studios License. See [LICENSE](LICENSE) for details.