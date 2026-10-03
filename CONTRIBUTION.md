# Contributing to HyperDuper Vanilla 🤝

Welcome! We are excited that you're interested in tinkering with, improving, or contributing to **HyperDuper Vanilla**. 

Whether you are a seasoned GLSL wizard, a mod developer adding compatibility for your dimension, or a curious player vibecoding with an AI assistant—**everyone is welcome!**

---

## ⚠️ Important Disclaimer & Maintenance Context

Before contributing, please keep in mind:
* **Provided "AS IS"**: HyperDuper Vanilla is an experimental, passion-driven fork provided strictly as-is without any warranties or performance guarantees.
* **Maintenance May Be Inactive**: The maintainers work on this project purely for fun in their spare time. Maintenance and issue reviews may be sporadic, delayed, or inactive.
* **No Pressure, Total Freedom**: There are zero expectations. If you build something cool, submit a PR! If you want to take the code in your own direction, feel free to fork this repository and create your own project.

---

## 🤖 AI Vibecoding Welcome

> **We openly embrace AI-assisted coding and vibecoding!**
>
> If you used Claude, Gemini, ChatGPT, or any other agentic AI to help write shader passes, optimize math, or draft translations, **that is 100% fine!**
>
> All we ask is:
> 1. **Test it in-game**: Make sure it compiles and actually looks good in Minecraft (`./gradlew runClient` or Iris).
> 2. **Pass the Quality Gate**: Run `python3 scripts/quality_gate.py` to ensure there are no compilation errors or broken `#include` statements.
> 3. **Keep it understandable**: Add comments explaining what the code is doing so others can learn from it.

---

## 🚀 Quickstart for Developers

### 1. Prerequisites
* Java 21 or Java 25 (for Loom / Quilt test environment)
* Python 3.8+ (for quality gate and profiling scripts)
* `glslangValidator` (optional but recommended for shader linting, installable via package manager)

### 2. Testing Locally with Live Reload
You can run an isolated client instance with Quilt, Sodium, Iris, and Voxy pre-configured:
```bash
# Launch the client:
./gradlew runClient
```
* **Instant Hot-Reload**: While Minecraft is running, edit any shader file in `shaders/` and press **`R`** in-game to recompile and reload immediately!

### 3. Validating Your Changes
Before opening a pull request, run the continuous quality gate:
```bash
python3 scripts/quality_gate.py
```
This runs 4 automated checks:
1. `glslangValidator` compilation across all shader programs.
2. Translation and language file consistency.
3. File length and cyclomatic complexity limits.
4. `#include` file existence verification.

You can also run the static performance profiler to ensure you haven't introduced GPU bottlenecks:
```bash
python3 scripts/profile_shaders.py
```

---

## 🎨 Coding Conventions & Style

To keep the codebase consistent and readable across multiple contributors and AI iterations:

### 1. Macro & Variable Naming
* Use `SCREAMING_SNAKE_CASE` for preprocessor macros and shader options:
  ```glsl
  #define GODRAYS_QUALITY 1
  #define MAX_RAY_STEPS 32
  ```
* Use `camelCase` for functions, variables, and struct members:
  ```glsl
  vec3 calculateAtmosphericHaze(vec3 worldPos, float viewDistance) {
      float fogDensity = getFogDensity(worldPos);
      return fogColor * fogDensity;
  }
  ```

### 2. Commenting & Spacing
* Leave a space after `//` or `/*`:
  ```glsl
  // Good: Clear explanation of math
  /* Also good: multi-line description */
  
  //Bad: no space
  ```
* In `shaders/shaders.properties`, keep menu rows organized in pairs (2 items per line) with `<empty>` padding for clean alignment.

### 3. Adding New Options & Localizations
* When adding a new shader option in `shaders/lib/settings.glsl` or `shaders/shaders.properties`, always add its localized description to `shaders/lang/en_US.lang`.
* Follow our **Sodium-style tooltip template**:
  ```properties
  option.MY_FEATURE = Feature Name
  option.MY_FEATURE.comment = Friendly plain-English summary of what this feature does.\n\n§e[Visual] §fWhat changes on the screen.\n§a[Performance: Low] §fEstimated framerate impact.\n§b[Tip] §7Helpful advice or recommended settings.
  ```

---

## 🌟 Adding Your Name to Contributors

You are a valued part of this project! When you submit a pull request, feel free to add your name and GitHub profile link to [**CONTRIBUTORS.md**](CONTRIBUTORS.md) (or [**TRANSLATORS.md**](TRANSLATORS.md) for localization work).

Thank you for helping make HyperDuper Vanilla vibrant, fun, and fast! 🚀