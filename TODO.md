# TO DO (for Eldeston)
Notes for pending features/bug fixes to be implemented categorized by importance.

## PENDING
* [ ] Create a custom shadow model view (low priority)

* [ ] Find a way to make translucent detection more dynamic (medium priority)

* [ ] Improve world properties calculation

* [ ] Rebuild pipeline and include visualization (high priority)

* [ ] Separate iPBR for all gbuffers (medium priority)

* [ ] Optimize DOF calculations with noise (low priority)
* [ ] Optimize day and night transition calculations (medium priority)

* [ ] Refactor uniform usage and remove unecessary ones (medium priority)
* [ ] Format the goodness knows how much nesting I used in my code because BROTHA EWWHH (maximum priority)

* [ ] Plan a more customizable iPBR system, such as enabling specific material types across a block group (medium priority)
* [ ] Evaluate a cheaper shadow distortion shape, smoothMax uses tanh per fragment and per volumetric step (low priority, affects shadow quality)

## CURRENT
* [ ] Implement bit packing for optimization
* [ ] Implement square style sun/moon

* [ ] Refactor parallax occlusion mapping
* [ ] Change cloud texture

* [ ] Improve fog calculation and settings (medium priority)
* [ ] Improve water absorption (low priority)
* [ ] Improve tonemapping (medium priority)
* [ ] Improve Distant Horizons depth
* [ ] Improve shader menu UI
    * [ ] General UI, organizing by usage
    * [ ] More iPBR options, enabling specific block families, or enabling new properties like emissive ores
    * [x] World config UI, improving expandability

* [ ] Find a way to separate sky light and terrain light, or implement a void sky property with permanent terrain light
* [ ] Improve albedo calculation, separating it from getPBR(), also improve parallax occlusion mapping

* [ ] Fix atmospheric fog division by zero when vertical fog density is 0 (`world-4` defaults to 0.000) (high priority)
* [ ] Fix `labPBR.glsl` entity IDs, it still tests 10130/10131/10132 instead of 20100/20200/20201 (medium priority)
* [ ] Fix sculk noise IDs in `gbuffers_terrain`, it tests 13005/13202 but sculk is 13105/13106 (medium priority)
* [ ] Decide what `PBR_MODE 0` should do, nothing tests `PBR_MODE > 0` so OFF behaves like Basic (medium priority)
* [ ] Assign or remove unused IDs: signs `12001` and entities `20000` to `20006` have no material code (low priority)
* [ ] Guard `getCellNoise` in `physics_ocean` for when `WATER_NORMAL` and `WATER_NOISE` are both off (low priority)
* [ ] Test the `##` token pasting in `worldResolver.glsl` on NVIDIA and Mesa (low priority)

## DONE
* [x] Rebalance block light range for gameplay
* [x] Fix missing vanilla fog mode implementations
* [x] Consider early linear color conversion to improve day cycle transition
* [x] Make aether available in no light environments by using fog instead (through vanilla or custom)
* [x] Update IPBR.md after the iPBR redesign (low priority, blocked by the item above)
* [x] Docs overhaul: DIMENSION.md and IPBR.md added, SETTINGS, FEATURES, PROGRAMS, ARCHITECTURE, OPTIMIZATION, and DOCUMENTATION updated for the per-dimension system

* [x] Replace skybox clouds completely with voxelized clouds
* [x] Abandon Optifine support (high priority)
* [x] Fix hand bobbing not working
* [x] Implement Voxy support

* [x] Optimize alpha testing (high priority)
* [x] Fix gbuffers_skytextured (medium priority)
* [x] Optimize block ids in block.properties (medium priority)

* [x] Finish programming dh_generic (medium priority)
* [x] Fix dragon death beam (medium priority) ?
* [x] Fix FXAA, it was broken the whole time (high priority)

* [x] Implement portal depth for Nether and End
* [x] Improve documentation (high priority)
* [x] Improve subsurface scattering
* [x] Improve shadow filtering