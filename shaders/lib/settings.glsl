// Shadow distortion factor
#define SHD_ENABLE // Enables shadows. Disable to use only fake shadows that uses lightmap
#define SHADOW_FILTER // Enables soft shadow filtering, if enabled shadows will appear softer by using noise. May impact performance.
#define SHD_COL // Enables shadow color from colored transparent objects.
#define RENDER_FOLIAGE_SHD // Enables cutout objects shadows.
#define ENABLE_SS // Enables subsurface scattering. 
#define UNDERWATER_CAUSTICS 1 // Enables underwater caustics. Shadow color must be enabled! [0 1 2]
#define AMBIENT_LIGHTING 0.10 // Overall ambient lighting value. Increase if you dislike the pitch black darkness, higher values may make lighting unrealistic. Set it to zero for a more realistic approach if you have SSGI enabled. Set it to 0.50 for nightvision. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50]

#define ANIMATE // Enables foliage animations, water animations etc.
#define CURRENT_SPEED 1.00 // Adjust liquid and under water flow speed. Affects underwater plants and liquids. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]
#define WIND_SPEED 1.00 // Adjust wind speed. Affects plants and swinging objects. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]
// #define WORLD_CURVATURE // Enable world curvature
#define WORLD_CURVATURE_SIZE 256 // World curvature size [-4096 -2048 -1024 -512 -256 -128 128 256 512 1024 2048 4096]
#define TIMELAPSE_MODE 0 // Enable timelapse mode. This smoothens the transition of animations of the sky, the foliage waving etc according to current world time instead of frame time. Set to fragment for water normals and sky only and full for the water normals, sky, and waves. This feature does not work on vanilla clouds, skybox, and the sun and moon. [0 1 2]

// Off by default
#define WHITE_MODE 0 // Enables white mode/textureless mode. White mode makes everything white. Black mode makes everything black. Foliage mode shows only foliage colors. Keeps materials on. [0 1 2 3]
// #define ZA_WARUDO // ZA WARUUUDOOOOOOOOOOOOOOO! TOKI WO TOMARE! Requires timelapse mode to be enabled.
#define ANTI_ALIASING 1 // Enables anti-aliasing. FXAA is fast and works with screenshot sizes. TAA is slower, doesn't work with screenshots, but smooths noise. Disable anti-aliasing on your shader menu before enabling this feature! [0 1 2]
// #define VIGNETTE // Enables vignette
#define VIGNETTE_INTENSITY 1 // Vignette intensity [1 2 3 4 5]

#define SATURATION 1.25 // Saturation, controls how much color saturation [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define EXPOSURE 1.00 // Exposure, controls color exposure [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define CONTRAST 1.25 // Contrast, controls color contrast [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

// #define AUTO_EXPOSURE // Enables real time auto exposure. Does not work with Optifine screenshots!
#define AUTO_EXPOSURE_SPEED 1.00 // Auto exposure temporal speed. Changes how fast or slow the auto exposure will adjust to the screen's exposure. Smaller values means slower, bigger values means faster. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define TINT_R 255 // Red tint value [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define TINT_G 255 // Red tint value value [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define TINT_B 255 // Red tint value value [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]

#define BLOOM // Enables bloom.
#define BLOOM_BRIGHTNESS 1.00 // Bloom brightness [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define LENS_FLARE // Enables lens flare.
#define LENS_FLARE_BRIGHTNESS 1.00 // Lens flare intensity. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

// #define DOF // Enables depth of field. Enables anti-aliasing for better results.
#define FOCAL_RANGE 8 // Focus range. Increase this value to put more blocks into focus. [1 2 4 8 16 32 64]
#define DOF_LOD 2 // Depth of field max lod size. Increase this value for more blur or if you have a bigger screen. [0 1 2 3 4 5 6 7 8 9 10]

// #define OUTLINES // Enables experimental outlines
#define OUTLINE_BRIGHTNESS 0.50 // Outline brightness. Set it to zero for black outlines, or 2 to highlighted outlines. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define OUTLINE_PIX_SIZE 2 // Outline pixel size. Adjust to change the thickness of the outlines [1 2 4 8 16 32 64]

#define WATER_NORM // Enables water normals
#define WATER_BRIGHTNESS 1.00 // Water brightness, lower values mean deeper colors [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define WATER_BLUR_SIZE 8.0 // Water normal map blur size, smaller means more defined waves, larger means smoother waves [1.0 2.0 4.0 8.0 16.0 32.0 64.0]
#define WATER_DEPTH_SIZE 64 // The normal map depth of the waves, the smaller the more depth it has [16 32 64 128 256]
#define WATER_TILE_SIZE 16 // Tile size of the water [4 8 16 24 32 40 48 56 64]
#define STYLIZED_WATER_ABSORPTION // Enables stylized water absorption. Changes water color based on depth.
#define WATER_FOAM // Enables water foam. Appears on the sides of most solid objects, including entities.
#define WATER_NOISE // Enables water noise. Varies the water brightness by noise similar to SDGP.

#define LAVA_BRIGHTNESS 1.00 // Lava brightness, lower values mean darker colors [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define LAVA_TILE_SIZE 32 // Tile size of the lava [4 8 16 24 32 40 48 56 64]
#define LAVA_NOISE // Enables lava noise. Varies the lava brightness by noise similar to Minecraft Dungeons.

// #define SSGI // Enables SSGI, currently experimental and may not be very optimized, may improve the ambience of dark areas despite the noisiness. Turn on TAA for best results.
#define SSGI_STEPS 20 // SSGI steps, more steps means more quality, and more quality means more performance [16 20 24 28 32]
#define SSGI_BISTEPS 4 // SSGI binary refinement steps, more steps means more accurate GI, and more quality means more performance [0 4 8 16]

#define SSR // Enables SSR, may not look good in certain areas
#define SSR_STEPS 20 // SSR steps, more steps means more quality, and more quality means more performance [16 20 24 28 32]
#define SSR_BISTEPS 4 // SSR binary refinement steps, more steps means more accurate reflections, and more quality means more performance [0 4 8 16]

// #define ROUGH_REFLECTIONS // Enables rougher objects to have rougher reflections. May show weird artifacts, but some AA might fix it.
// #define PREVIOUS_FRAME // Reads previous frame buffer colors alowing SSR or SSGI to have infinite bounces of light. Impacts performance!

#define DEFAULT_MAT 1 // Enables PBR. Default PBR depends on the vanilla albedo textures to map out the materials. Resource PBR uses your resource packs' PBR, if available. Resource PBR requires latest LabPBR version! [0 1 2]
#define ENVIRO_MAT // Enables enviroment materials. Environment materials affects your surrounding according to your environment such as rain.
// #define AUTO_GEN_NORM // Enables auto generated normals. Works if Default PBR is on. Works mostly on vanilla resource packs.
#define EMISSIVE_INTENSITY 8 // Emissive maps intensity. Does not affect lightmaps and requires PBR on. [2 4 8 16 32]
#define NOISE_SPEED 8 // The speed in which the noise randomises each frame. Useful for TAA. This effect is visible only when TAA is enabled. [2 4 8 16 32]
#define BUFFER_VIEW gcolor // Views different stored buffers. [gcolor colortex1 colortex2 colortex3 colortex4 colortex5 colortex6 colortex7]

// #define PARALLAX_OCCLUSION // Enables parallax occlusion. Requires LabPBR on and a resource pack with LabPBR enabled materials.
#define PARALLAX_DEPTH 0.25 // Parallax occlusion depth amount. Increase for more depth. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50]
#define PARALLAX_STEPS 128 // Parallax occlusion step ammount. Increase for improved POM quality. [16 32 64 128 256 512]

#define PARALLAX_SHADOWS // Enables parallax self shadowing.
#define PARALLAX_SHD_STEPS 32 // Parallax self shadowing step ammount. Increase for improved self shadowing quality. [16 32 64 128 256 512]

// #define SLOPE_NORMALS // Enables slope normals. Disable this feature if you're using a high resolution pack with normal maps. Thanks @Null!

#define STORY_MODE_CLOUDS // Uses procedurally generated clouds (a.k.a. aerogel clouds) instead of vanilla clouds. Disable vanilla clouds for proper results.
// #define DOUBLE_VANILLA_CLOUDS // Adds another layer of vanilla clouds (does not apply to story mode clouds), may use up performance.
#define CLOUD_FADE // Allow clouds to fade to different phases (affects on both vanilla and story mode clouds).
#define SECOND_CLOUD_HEIGHT 64.0 // 2nd layer cloud height, if double vanilla clouds is on [-128.0 -112.0 -96.0 -80.0 -64.0 -48.0 -32.0 -16.0 16.0 32.0 48.0 64.0 80.0 96.0 112.0 128.0]
#define FADE_SPEED 0.20 // Cloud fade speed [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]

#define VOL_LIGHT_BRIGHTNESS 0.50 // The brightness/value of volumetric lighting, set it to zero to disable it [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define VOL_LIGHT // Enables volumetric lighting.
#define MIST_GROUND_FOG_BRIGHTNESS 0.50 // The brightness/value of mist/ground fog. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define BORDER_FOG // Enables border fog to cover world edges
#define SUN_MOON_TYPE 0 // Sun and moon type [0 1 2]
#define SUN_MOON_INTENSITY 5 // The sun or moon's intensity. Also affects specular reflections. [2 3 4 5 6 7 8]
#define SKYBOX_BRIGHTNESS 2.00 // Sky box brightness. [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00 2.05 2.10 2.15 2.20 2.25 2.30 2.35 2.40 2.45 2.50 2.55 2.60 2.65 2.70 2.75 2.80 2.85 2.90 2.95 3.00 3.05 3.10 3.15 3.20 3.25 3.30 3.35 3.40 3.45 3.50 3.55 3.60 3.65 3.70 3.75 3.80 3.85 3.90 3.95 4.00]

#define BLOCKLIGHT_R 255 // Red value [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define BLOCKLIGHT_G 235 // Green value [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define BLOCKLIGHT_B 215 // Blue value [0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255]
#define BLOCKLIGHT_I 1.00 // Intensity value [0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define GAMMA 2.2 // Disables gamma correction completely to return to the legacy look of SDV. [1.0 2.2]
#define RCPGAMMA 1.0 / GAMMA