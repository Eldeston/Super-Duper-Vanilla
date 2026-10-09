# Buffer Main Bus

**Related documents**: [ARCHITECTURE.md](ARCHITECTURE.md) for stage context; [PROGRAMS.md](PROGRAMS.md) for program definitions and conditions.

A lane represents a render target. A station represents a shader program reading from or writing to that lane. The bus below follows the current shader sources and `shaders.properties`; optional stations run only when their feature is enabled.

## Color-Target Main Bus

```mermaid
flowchart TB
    subgraph BUS["Color-target main bus"]
        direction TB

        subgraph L0["Lane: colortex0 · half resolution"]
            direction LR
            C2W["Composite2<br/>W: volumetrics"] --> C3R["Composite3<br/>R: upsample input"] --> C8W["Composite8<br/>W: bloom tiles"] --> C910["Composite9-10<br/>R/W: bloom blur"] --> C11["Composite11<br/>R/W: bloom + lens flare"] --> C12R["Composite12<br/>R: bloom input"]
        end

        subgraph L1["Lane: colortex1 · normals"]
            direction LR
            G1W["Gbuffers<br/>W: surface normals"] --> C0R1["Composite0<br/>R: deferred shading"]
        end

        subgraph L2["Lane: colortex2 · albedo + AO"]
            direction LR
            G2W["Gbuffers<br/>W: albedo"] --> DW2["Deferred<br/>W: SSAO in alpha"] --> C0R2["Composite0<br/>R: material data"]
        end

        subgraph L3["Lane: colortex3 · material / post color"]
            direction LR
            G3W["Gbuffers<br/>W: material data"] --> C0R3["Composite0<br/>R: material mask"] --> C5["Composite5<br/>R/W: FXAA when selected"] --> C12W3["Composite12<br/>W: final post color"] --> FINAL["Final<br/>R: display color"]
        end

        subgraph L4["Lane: colortex4 · HDR scene"]
            direction LR
            G4W["Gbuffers<br/>W: forward scene"] --> C0RW4["Composite0<br/>R/W: deferred shading"] --> C3RW4["Composite3<br/>R/W: add volumetrics"] --> C4RW4["Composite4<br/>R/W: TAA"] --> C6RW4["Composite6<br/>R/W: motion blur"] --> C7RW4["Composite7<br/>R/W: DOF"] --> C8R4["Composite8<br/>R: bloom source"] --> C12R4["Composite12<br/>R: final composition"]
        end

        subgraph L5["Lane: colortex5 · temporal / exposure data"]
            direction LR
            C4RW5["Composite4<br/>R/W: temporal history when enabled"] --> C12RW5["Composite12<br/>R/W: exposure history when enabled"]
        end
    end
```

**Legend**: `R` = read, `W` = write, `R/W` = read and write. Composite1 is disabled and has no active data station. The arrows show data movement within a lane, not every shader execution dependency; for exact program conditions see [PROGRAMS.md](PROGRAMS.md).

## Lane Specifications

| Lane | Format | Payload and lifecycle | Resolution |
|---|---|---|---|
| `colortex0` | `R11F_G11F_B10F` | Half-resolution volumetrics, then bloom intermediates | `0.5 × 0.5` view size |
| `colortex1` | `RGB16_SNORM` | Surface normals for deferred shading | Full view size |
| `colortex2` | `RGBA8` | Albedo in RGB; deferred SSAO data in alpha | Full view size |
| `colortex3` | `RGB8` | Material data for deferred shading, then FXAA/final post color | Full view size |
| `colortex4` | `R11F_G11F_B10F` | HDR scene through shading and post-processing | Full view size |
| `colortex5` | `RGBA16F` | Conditional temporal history and auto-exposure state | Full view size |

The target formats are declared in `shaders/main/final.glsl`; the half-size allocation for `colortex0` is configured in `shaders/shaders.properties`. Total memory use also depends on view size, depth targets, shadow-map resolution, and implementation details, so this guide does not give a fixed VRAM total.

## Attachment Side Lanes

These depth and shadow attachments feed the color-target stations but are not part of the six-color-target bus.

| Attachment | Producer | Main consumers | Role |
|---|---|---|---|
| `depthtex0` | Gbuffers | Deferred shading, volumetrics, TAA, motion blur, lens-flare visibility | Opaque scene depth |
| `depthtex1` | Translucent rendering | DOF pass (`composite7`) | Translucent-aware depth |
| `shadowtex0` | Shadow programs | Deferred/direct-light shading | Shadow depth |
| `shadowtex1` | Shadow comparison pass when configured | Shadow sampling | Optional comparison depth |
| `shadowcolor0` | Shadow programs when colored shadows are enabled | Shadow sampling in lighting | Colored/translucent shadow data |
| DH / Voxy depth textures | Distant Horizons / Voxy integrations | Depth-aware passes when those integrations are active | External scene depth |

## Lane Rules

- Read/write behavior and feature conditions are defined by the shader program and `shaders.properties`; consult [PROGRAMS.md](PROGRAMS.md) for that canonical pass map.
- `colortex0` is a reused intermediate: volumetrics use it before bloom reuses it later in the frame.
- `colortex3` changes role after deferred shading has consumed its material data; later passes use it for post-processed color.
- `colortex5` is only a temporal lane when relevant features are enabled; do not assume every frame writes history.
- When `CLOUD_TYPE != 0`, `shaders.properties` also binds the cloud texture to `colortex0` for selected programs. This is a program-specific texture binding, not a separate cloud-glow phase in the bus.
