// Material PBR struct
struct matPBR{
    // Albedo texture
    vec4 albedo;
    // Normal map
    vec3 normal;
    // Metalic map
    float metallic;
    // Emissive map
	float emissive;
    // Smoothness map
    float smoothness;
    // Ambient map
    float ambient;
    // Porosity
    float porosity;
    // Subsurface scattering
    float ss;
    // POM self shadows
    float parallaxShd;
};

// Derivatives
vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);

uniform sampler2D texture;

#ifdef AUTO_GEN_NORM
#endif

#ifdef ENVIRO_MAT
#endif

#if (defined TERRAIN || defined WATER) && defined ENVIRO_MAT && !defined FORCE_DISABLE_WEATHER
    uniform float isPrecipitationRain;
    uniform float wetness;

    vec2 getNoiseDataCubic(vec2 uv){
        float pixSize = 1.0 / noiseTextureResolution;

        float a = smoothen(fract(uv.x * noiseTextureResolution));

        vec2 horizontal0 = mix(texture2D(noisetex, uv).xy, texture2D(noisetex, uv + vec2(pixSize, 0)).xy, a);
        vec2 horizontal1 = mix(texture2D(noisetex, uv + vec2(0, pixSize)).xy, texture2D(noisetex, uv + pixSize).xy, a);
        
        return mix(horizontal0, horizontal1, smoothen(fract(uv.y * noiseTextureResolution)));
    }

    void enviroPBR(inout matPBR material, in vec2 worldPos){
        float rainMatFact = sqrt(max(0.0, TBN[2].y) * smoothstep(0.8, 0.9, lmCoord.y) * wetness * isPrecipitationRain * (1.0 - material.porosity));

        if(rainMatFact > 0.005){
            vec2 noiseData = getNoiseDataCubic(worldPos * 0.001953125).xy;
            rainMatFact *= smoothstep(0.15, 0.6, (noiseData.y + noiseData.x) * 0.5);
            
            material.normal = mix(material.normal, TBN[2], rainMatFact);
            material.metallic = max(0.02 * rainMatFact, material.metallic);
            material.smoothness = mix(material.smoothness, 0.96, rainMatFact);
            material.albedo.rgb *= 1.0 - rainMatFact * 0.5;
        }
    }
#endif

#if DEFAULT_MAT == 2
    uniform sampler2D normals;
    uniform sampler2D specular;

    // This is for Optifine to detect the option...
    #ifdef PARALLAX_OCCLUSION
    #endif

    #ifdef PARALLAX_SHADOWS
    #endif

    #if (defined TERRAIN || defined WATER || defined BLOCK || defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER) && defined PARALLAX_OCCLUSION
        vec2 getParallaxOffset(vec3 dirT){
            return normalize(dirT.xy) * (sqrt(lengthSquared(dirT) - dirT.z * dirT.z) * PARALLAX_DEPTH / dirT.z);
        }

        vec2 parallaxUv(vec2 startUv, vec2 endUv, out vec3 currPos){
            float stepSize = 1.0 / PARALLAX_STEPS;
            endUv *= stepSize * PARALLAX_DEPTH;

            float texDepth = texture2DGradARB(normals, fract(startUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;
            float traceDepth = 1.0;

            for(int i = 0; i < PARALLAX_STEPS; i++){
                if(texDepth >= traceDepth) break;
                startUv += endUv;
                traceDepth -= stepSize;
                texDepth = texture2DGradARB(normals, fract(startUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;
            }

            currPos = vec3(startUv - endUv, traceDepth + stepSize);
            return startUv;
        }

        #if defined PARALLAX_SHADOWS && defined WORLD_LIGHT
            float parallaxShadow(vec3 currPos, vec2 lightDir) {
                float stepSize = 1.0 / PARALLAX_SHD_STEPS;
                vec2 stepOffset = stepSize * lightDir;
                
                float traceDepth = currPos.z;
                vec2 traceUv = currPos.xy;

                for(int i = int(traceDepth * PARALLAX_SHD_STEPS); i < PARALLAX_SHD_STEPS; i++){
                    if(texture2DGradARB(normals, fract(traceUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a >= traceDepth) return pow(i * stepSize, 16.0);
                    // if(texture2DGradARB(normals, fract(traceUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a >= traceDepth) return 0.0;
                    traceUv += stepOffset;
                    traceDepth += stepSize;
                }

                return 1.0;
            }
        #endif

        #ifdef SLOPE_NORMALS
            vec2 getSlopeNormals(vec3 viewT, vec2 texUv, float traceDepth){
                vec2 texRes = textureSize(normals, 0);
                vec2 texPixSize = 1.0 / texRes;

                vec2 texSnapped = floor(texUv * texRes) * texPixSize;
                vec2 texOffset = texUv - texSnapped - 0.5 * texPixSize;
                vec2 stepSign = sign(-viewT.xy);

                vec2 texX = texSnapped + vec2(texPixSize.x * stepSign.x, 0);
                float heightX = texture2DGradARB(normals, texX, dcdx, dcdy).a;
                bool hasX = traceDepth > heightX && sign(texOffset.x) == stepSign.x;

                vec2 texY = texSnapped + vec2(0, texPixSize.y * stepSign.y);
                float heightY = texture2DGradARB(normals, texY, dcdx, dcdy).a;
                bool hasY = traceDepth > heightY && sign(texOffset.y) == stepSign.y;

                if(abs(texOffset.x) < abs(texOffset.y)){
                    if(hasY) return vec2(0, stepSign.y);
                    if(hasX) return vec2(stepSign.x, 0);
                } else {
                    if(hasX) return vec2(stepSign.x, 0);
                    if(hasY) return vec2(0, stepSign.y);
                }

                float s = step(abs(viewT.y), abs(viewT.x));
                return vec2(1.0 - s, s) * stepSign;
            }
        #endif
    #endif

    void getPBR(inout matPBR material, in vec3 eyePlayerPos, in int id){
        vec2 texUv = texCoord;

        #if (defined TERRAIN || defined WATER || defined BLOCK || defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER) && defined PARALLAX_OCCLUSION
            vec3 viewDir = -eyePlayerPos * TBN;

            vec3 currPos;
            
            // Exclude signs, due to a missing text bug
            if(id != 10019) texUv = fract(parallaxUv(vTexCoord, viewDir.xy / -viewDir.z, currPos)) * vTexCoordScale + vTexCoordPos;
        #endif

        // Assign albedo
        material.albedo = texture2DGradARB(texture, texUv, dcdx, dcdy);

        // Alpha test, discard immediately
        if(material.albedo.a <= ALPHA_THRESHOLD) discard;

        // Assign default normal map
        material.normal = TBN[2];

        // Get raw textures
        vec4 normalAOH = texture2DGradARB(normals, texUv, dcdx, dcdy);
        vec4 SRPSSE = texture2DGradARB(specular, texUv, dcdx, dcdy);

        // Decode and extract the materials
        // Extract normals
        vec3 normalMap = vec3(normalAOH.xy * 2.0 - 1.0, 0);
        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));

        // Assign porosity
        material.porosity = SRPSSE.b < 0.252 ? SRPSSE.b * 3.984 : 0.0;

        // Assign SS
        material.ss = SRPSSE.b > 0.252 ? (SRPSSE.b - 0.250980392) * 1.33507853 : 0.0;

        // Assign smoothness
        material.smoothness = SRPSSE.r;

        // Assign reflectance
        material.metallic = SRPSSE.g;

        // Assign emissive
        material.emissive = SRPSSE.a * float(SRPSSE.a != 1);

        // Assign ambient
        #ifdef TERRAIN
            // Apply vanilla AO with it in terrain
            material.ambient = glcolorAO * normalAOH.b;
        #else
            // For others, don't use vanilla AO
            material.ambient = normalAOH.b;
        #endif

        #ifdef TERRAIN
            // If lava and fire
            if(id == 10002 || id == 10003) material.emissive = 1.0;

            // Foliage and corals
            else if((id >= 10004 && id <= 10015) || id == 10033 || id == 10036) material.ss = 1.0;
        #endif

        // Get parallax shadows
        material.parallaxShd = 1.0;

        #if (defined TERRAIN || defined WATER || defined BLOCK || defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER) && defined PARALLAX_OCCLUSION
            if(id != 10019){
                #ifdef SLOPE_NORMALS
                    if(texture2DGradARB(normals, texUv, dcdx, dcdy).a > currPos.z) normalMap = vec3(getSlopeNormals(-viewDir, texUv, currPos.z), 0);
                #endif

                #if defined PARALLAX_SHADOWS && defined WORLD_LIGHT
                    if(dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)) > 0.000001)
                        material.parallaxShd = parallaxShadow(currPos, getParallaxOffset(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z) * TBN));
                    else material.parallaxShd = material.ss;
                #endif
            }
        #endif

        // Assign normal
        material.normal = TBN * normalize(normalMap);

        #ifdef WATER
            // If water
            if(id == 10001){
                material.smoothness = 0.96;
                material.metallic = 0.02;
            }
            
            // Nether portal
            else if(id == 10018){
                material.smoothness = 0.96;
                material.metallic = 0.04;
                material.emissive = maxC(material.albedo.rgb);
            }
        #endif

        #if defined ENTITIES || defined ENTITIES_GLOWING
            // Experience orbs and fireballs
            if(id == 10102 || id == 10103) material.emissive = 1.0;
        #endif

        #if WHITE_MODE == 0
            material.albedo.rgb *= glcolor;
        #elif WHITE_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo.rgb = glcolor;
        #endif

        material.smoothness = min(material.smoothness, 0.96);

        // Ambient occlusion fix
        #if defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER
            if(id <= 0) material.ambient = 1.0;
        #endif

        #ifdef BLOCK
            if(id == 10019) material.ambient = 1.0;
        #endif
    }
#else
    void getPBR(inout matPBR material, in vec3 eyePlayerPos, in int id){
        // Assign albedo
        material.albedo = texture2DGradARB(texture, texCoord, dcdx, dcdy);

        // Alpha test, discard immediately
        if(material.albedo.a <= ALPHA_THRESHOLD) discard;

        // Assign default normal map
        material.normal = TBN[2];

        // Generate bumped normals
        #if (defined TERRAIN || defined WATER || defined BLOCK) && defined AUTO_GEN_NORM
            if(id != 10019){
                float d0 = length(material.albedo.rgb);
                float d1 = length(texture2DGradARB(texture, fract(vTexCoord + vec2(0.0125, 0)) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);
                float d2 = length(texture2DGradARB(texture, fract(vTexCoord + vec2(0, 0.0125)) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);

                material.normal = TBN * normalize(vec3(d0 - d1, d0 - d2, 0.125));
            }
        #endif

        // Default material if not specified
        material.metallic = 0.04; material.emissive = 0.0;
        material.smoothness = 0.0; material.ss = 0.0;
        material.parallaxShd = 1.0; material.porosity = 0.0;

        #ifdef TERRAIN
            // Apply vanilla AO with it in terrain
            material.ambient = glcolorAO;
        #else
            // For others, don't use vanilla AO
            material.ambient = 1.0;
        #endif

        #ifdef TERRAIN
            // If lava and fire
            if(id == 10002 || id == 10003) material.emissive = 1.0;

            // Foliage and corals
            else if((id >= 10004 && id <= 10015) || id == 10033 || id == 10036) material.ss = 1.0;
        #endif

        #ifdef WATER
            // If water
            if(id == 10001){
                material.smoothness = 0.96;
                material.metallic = 0.02;
            }
            
            // Nether portal
            else if(id == 10018){
                material.smoothness = 0.96;
                material.metallic = 0.04;
                material.emissive = maxC(material.albedo.rgb);
            }
        #endif

        #if defined ENTITIES || defined ENTITIES_GLOWING
            // Experience orbs and fireballs
            if(id == 10102 || id == 10103) material.emissive = 1.0;
        #endif
        
        #if DEFAULT_MAT == 1
            #ifdef TERRAIN
                // Glow berries
                if(id == 10033) material.emissive = material.albedo.r + material.albedo.g > material.albedo.g * 2.0 ? smoothstep(0.3, 0.9, maxC(material.albedo.rgb)) : material.emissive;

                // Stems
                else if(id == 10034) material.emissive = material.albedo.r < 0.1 ? maxC(material.albedo.rgb) * 0.72 : material.emissive;
                else if(id == 10035) material.emissive = material.albedo.b < 0.16 && material.albedo.r > 0.4 ? maxC(material.albedo.rgb) * 0.72 : material.emissive;

                // Fungus
                else if(id == 10036) material.emissive = max2(material.albedo.rg) > 0.8 ? 0.72 : material.emissive;
                else if(id == 10037) material.emissive = smoothstep(1.2, 1.8, material.albedo.r + material.albedo.g + material.albedo.b);

                // Emissives
                else if(id == 10038) material.emissive = smoothstep(0.88, 1.0, maxC(material.albedo.rgb));
                else if(id == 10039 || id == 10040) material.emissive = smoothstep(0.64, 0.8, maxC(material.albedo.rgb));

                // Redstone stuff
                else if((id == 10041 || id == 10068) && material.albedo.r > material.albedo.b * 2.4){
                    material.emissive = float(material.albedo.r > 0.5);
                    material.smoothness = 0.93 * sqrt(material.albedo.r);
                    material.metallic = 1.0;
                }

                // Redstone block
                else if(id == 10042){
                    material.emissive = 1.0;
                    material.smoothness = 0.93 * material.albedo.r;
                    material.metallic = 1.0;
                }

                // End portal frame
                else if(id == 10043 && material.albedo.g + material.albedo.b > material.albedo.r * 2.0) material.emissive = smoothstep(0.0, 0.5, material.albedo.g - material.albedo.b);

                // Gem ores
                else if(id == 10048 && (material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b) && length(material.albedo.rgb) > 0.45){
                    material.smoothness = 0.93 * min(1.0, material.albedo.r + material.albedo.g + material.albedo.b);
                    material.metallic = 0.17;
                }

                // Gem blocks
                else if(id == 10050){
                    material.smoothness = 0.96 * sqrt(min(1.0, material.albedo.r + material.albedo.g + material.albedo.b));
                    material.metallic = 0.17;
                }

                // Crying obsidian emissives
                else if(id == 10051){
                    material.smoothness = 0.96 * sqrt(min(1.0, material.albedo.r + material.albedo.g + material.albedo.b));
                    material.emissive = cubed(length(material.albedo.rgb));
                    material.metallic = 0.17;
                }

                // Netherack gem ores
                else if(id == 10049 && material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                    material.smoothness = 0.93 * min(1.0, material.albedo.r + material.albedo.g + material.albedo.b);
                    material.metallic = 0.16;
                }

                // Metal ores
                else if(id == 10064 && (material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b) && length(material.albedo.rgb) > 0.45){
                    material.smoothness = 0.93 * maxC(material.albedo.rgb);
                    material.metallic = 1.0;
                }

                // Netherack metal ores
                else if(id == 10065 && max2(material.albedo.rg) > 0.6){
                    material.smoothness = 0.93 * maxC(material.albedo.rgb);
                    material.metallic = 1.0;
                }

                // Metal blocks
                else if(id == 10066){
                    material.smoothness = 0.96 * squared(maxC(material.albedo.rgb));
                    material.metallic = 1.0;
                }

                // Dark metals
                else if(id == 10067){
                    material.smoothness = sqrt((material.albedo.r + material.albedo.g + material.albedo.b) * 0.333);
                    material.metallic = 1.0;
                }

                // Rails
                else if(id == 10068 && material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                    material.smoothness = 0.96 * min(1.0, material.albedo.r + material.albedo.g + material.albedo.b);
                    material.metallic = 1.0;
                }

                // Polished blocks
                else if(id == 10080) material.smoothness = sqrt((material.albedo.r + material.albedo.g + material.albedo.b) * 0.333);
            #endif

            #ifdef WATER
                // Glass and ice
                if(id == 10044 || id == 10045) material.smoothness = 0.96;

                // Gelatin
                else if(id == 10046) material.smoothness = 0.96;
            #endif
        #endif

        #if WHITE_MODE == 0
            material.albedo.rgb *= glcolor;
        #elif WHITE_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo.rgb = glcolor;
        #endif
    }
#endif
