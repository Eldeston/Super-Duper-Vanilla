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

    void enviroPBR(inout matPBR material){
        float rainMatFact = fastSqrt(max(0.0, TBN[2].y) * smoothen(saturate((lmCoord.y - 0.8) * 10.0)) * wetness * isPrecipitationRain * (1.0 - material.porosity));

        if(rainMatFact > 0.005){
            vec2 noiseData = texture2D(noisetex, worldPos.xz * 0.001953125).xy;
            rainMatFact *= saturate(noiseData.y + noiseData.x - 0.25);
            
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
            return dirT.xy * (PARALLAX_DEPTH / dirT.z);
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
            uniform ivec2 atlasSize;
            
            vec2 getSlopeNormals(vec3 viewT, vec2 texUv, float traceDepth){
                vec2 texPixSize = 1.0 / atlasSize;

                vec2 texSnapped = floor(texUv * atlasSize) * texPixSize;
                vec2 texOffset = texUv - texSnapped - texPixSize * 0.5;
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
                }else{
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
            if(id != 10018) texUv = fract(parallaxUv(vTexCoord, viewDir.xy / -viewDir.z, currPos)) * vTexCoordScale + vTexCoordPos;
        #endif

        // Assign albedo
        material.albedo = texture2DGradARB(texture, texUv, dcdx, dcdy);

        #if !(defined ENTITIES || defined ENTITIES_GLOWING)
            // Alpha test, discard immediately
            if(material.albedo.a <= ALPHA_THRESHOLD) discard;
        #endif

        // Assign default normal map
        material.normal = TBN[2];

        // Get raw textures
        vec4 normalAOH = texture2DGradARB(normals, texUv, dcdx, dcdy);
        vec4 SRPSSE = texture2DGradARB(specular, texUv, dcdx, dcdy);

        // Decode and extract the materials
        // Extract normals
        vec3 normalMap = vec3(normalAOH.xy * 2.0 - 1.0, 0);
        // Get the z normal direction and clamp to 0.0 (NaN fix)
        normalMap.z = max(0.0, sqrt(1.0 - dot(normalMap.xy, normalMap.xy)));

        // Assign porosity
        material.porosity = SRPSSE.b < 0.252 ? SRPSSE.b * 3.984 : 0.0;

        // Assign SS
        material.ss = SRPSSE.b > 0.252 ? (SRPSSE.b - 0.2509804) * 1.3350785 : 0.0;

        // Assign smoothness
        material.smoothness = min(SRPSSE.r, 0.96);

        // Assign reflectance
        material.metallic = SRPSSE.g;

        // Assign emissive
        material.emissive = SRPSSE.a != 1 ? SRPSSE.a : 0.0;

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
            if(id == 10001 || id == 10002) material.emissive = 1.0;

            // Foliage and corals
            if((id >= 10003 && id <= 10014) || id == 10033 || id == 10036) material.ss = 1.0;
        #endif

        // Get parallax shadows
        material.parallaxShd = 1.0;

        #if (defined TERRAIN || defined WATER || defined BLOCK || defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER) && defined PARALLAX_OCCLUSION
            if(id != 10018){
                #ifdef SLOPE_NORMALS
                    if(texture2DGradARB(normals, texUv, dcdx, dcdy).a > currPos.z) normalMap = vec3(getSlopeNormals(-viewDir, texUv, currPos.z), 0);
                #endif

                #if defined PARALLAX_SHADOWS && defined WORLD_LIGHT
                    if(dot(material.normal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z)) > 0.001)
                        material.parallaxShd = parallaxShadow(currPos, getParallaxOffset(vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z) * TBN));
                    else material.parallaxShd = material.ss;
                #endif
            }
        #endif

        // Assign normal
        material.normal = TBN * normalize(normalMap);

        #ifdef WATER
            // If water
            if(id == 10000){
                material.smoothness = 0.96;
                material.metallic = 0.02;
            }
            
            // Nether portal
            if(id == 10017){
                material.smoothness = 0.96;
                material.metallic = 0.04;
                material.emissive = maxOf(material.albedo.rgb);
            }
        #endif

        #if defined ENTITIES || defined ENTITIES_GLOWING
            // Experience orbs and fireballs
            if(id == 10130 || id == 10131) material.emissive = maxOf(material.albedo.rgb);
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

        // Ambient occlusion fix
        #if defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER
            if(id <= 0) material.ambient = 1.0;
        #endif

        #ifdef BLOCK
            if(id == 10018) material.ambient = 1.0;
        #endif
    }
#else
    void getPBR(inout matPBR material, in vec3 eyePlayerPos, in int id){
        // Assign albedo
        material.albedo = texture2DGradARB(texture, texCoord, dcdx, dcdy);

        #if !(defined ENTITIES || defined ENTITIES_GLOWING)
            // Alpha test, discard immediately
            if(material.albedo.a <= ALPHA_THRESHOLD) discard;
        #endif

        // Assign default normal map
        material.normal = TBN[2];

        // Generate bumped normals
        #if (defined TERRAIN || defined WATER || defined BLOCK) && defined AUTO_GEN_NORM
            if(id != 10018){
                float d0 = sumOf(material.albedo.rgb);
                float d1 = sumOf(texture2DGradARB(texture, fract(vec2(vTexCoord.x + 0.015625, vTexCoord.y)) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);
                float d2 = sumOf(texture2DGradARB(texture, fract(vec2(vTexCoord.x, vTexCoord.y + 0.015625)) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);

                material.normal = TBN * normalize(vec3(d0 - d1, d0 - d2, 0.25));
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
            if(id == 10001 || id == 10002) material.emissive = 1.0;

            // Foliage and corals
            if((id >= 10003 && id <= 10014) || id == 10033 || id == 10036) material.ss = 1.0;
        #endif

        #ifdef WATER
            // If water
            if(id == 10000){
                material.smoothness = 0.96;
                material.metallic = 0.02;
            }
            
            // Nether portal
            if(id == 10017){
                material.smoothness = 0.96;
                material.metallic = 0.04;
                material.emissive = maxOf(material.albedo.rgb);
            }
        #endif

        #if defined ENTITIES || defined ENTITIES_GLOWING
            // Experience orbs and fireballs
            if(id == 10130 || id == 10131) material.emissive = maxOf(material.albedo.rgb);
        #endif
        
        #if DEFAULT_MAT == 1
            #ifdef TERRAIN
                // Glow lichen
                if(id == 10032) material.emissive = material.albedo.r > material.albedo.b ? 1.0 : 0.0;

                // Glow berries
                if(id == 10033) material.emissive = material.albedo.r + material.albedo.g > material.albedo.g * 2.0 ? smoothstep(0.3, 0.9, maxOf(material.albedo.rgb)) : material.emissive;

                // Stems
                if(id == 10034) material.emissive = material.albedo.r < 0.1 ? maxOf(material.albedo.rgb) * 0.72 : material.emissive;
                if(id == 10035) material.emissive = material.albedo.b < 0.16 && material.albedo.r > 0.4 ? maxOf(material.albedo.rgb) * 0.72 : material.emissive;

                // Fungus
                if(id == 10036) material.emissive = maxOf(material.albedo.rg) > 0.8 ? 0.72 : material.emissive;

                // Light emitting blocks
                if(id == 10048) material.emissive = saturate(sumOf(material.albedo.rgb) * 1.33333332 - 2.0);
                if(id == 10049) material.emissive = cubed(max(0.0, sumOf(material.albedo.rgb) * 1.33333332 - 3.0));
                if(id == 10050 || id == 10051) material.emissive = squared(squared(saturate(sumOf(material.albedo.rgb) * 0.83333333 - 1)));
                if(id == 10052) material.emissive = smoothen(max(0.0, maxOf(material.albedo.rgb) - 0.75) * 4.0);
                if(id == 10053) material.emissive = exp(sumOf(material.albedo.rgb) * 2.66666664 - 8.0);
                
                // Sculk
                if(id == 10057) material.emissive = cubed(max(0.0, material.albedo.b - material.albedo.r));

                // Redstone stuff
                if((id == 10054 || id == 10100) && material.albedo.r > material.albedo.b * 2.4){
                    material.emissive = float(material.albedo.r > 0.5);
                    material.smoothness = 0.9;
                    material.metallic = 1.0;
                }

                // Redstone block
                if(id == 10055){
                    material.emissive = 0.45;
                    material.smoothness = 0.9 * material.albedo.r;
                    material.metallic = 1.0;
                }

                // End portal frame
                if(id == 10056 && material.albedo.g + material.albedo.b > material.albedo.r * 2.0) material.emissive = smoothstep(0.0, 0.5, material.albedo.g - material.albedo.b);

                // Gem ores
                if(id == 10080 && (material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b) && length(material.albedo.rgb) > 0.45){
                    material.smoothness = min(0.93, material.albedo.r + material.albedo.g + material.albedo.b);
                    material.metallic = 0.17;
                }

                // Gem blocks
                if(id == 10082){
                    material.smoothness = fastSqrt(min(0.8, material.albedo.r + material.albedo.g + material.albedo.b));
                    material.metallic = 0.17;
                }

                // Crying obsidian
                if(id == 10083){
                    material.smoothness = fastSqrt(min(0.8, material.albedo.r + material.albedo.g + material.albedo.b));
                    material.emissive = cubed(maxOf(material.albedo.rgb));
                    material.metallic = 0.17;
                }

                // Amethyst
                if(id == 10084 || id == 10085){
                    material.smoothness = (material.albedo.r + material.albedo.g + material.albedo.b) * 0.333;
                    material.emissive = material.smoothness * material.smoothness * material.smoothness * material.smoothness * (id == 10085 ? material.smoothness * material.smoothness * material.smoothness * material.smoothness * material.smoothness * material.smoothness : material.smoothness);
                    material.metallic = 0.17;
                }

                // Netherack gem ores
                if(id == 10081 && material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                    material.smoothness = min(0.93, material.albedo.r + material.albedo.g + material.albedo.b);
                    material.metallic = 0.17;
                }

                // Metal ores
                if(id == 10096 && (material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b) && length(material.albedo.rgb) > 0.45){
                    material.smoothness = (material.albedo.r + material.albedo.g + material.albedo.b) * 0.333;
                    material.metallic = 1.0;
                }

                // Netherack metal ores
                if(id == 10097 && maxOf(material.albedo.rg) > 0.6){
                    material.smoothness = (material.albedo.r + material.albedo.g + material.albedo.b) * 0.333;
                    material.metallic = 1.0;
                }

                // Metal blocks
                if(id == 10098){
                    material.smoothness = (material.albedo.r + material.albedo.g + material.albedo.b) * 0.333;
                    material.metallic = 1.0;
                }

                // Dark metals
                if(id == 10099){
                    material.smoothness = (material.albedo.r + material.albedo.g + material.albedo.b) * 0.1998 + 0.4;
                    material.metallic = 1.0;
                }

                // Rails
                if(id == 10100 && material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                    material.smoothness = (material.albedo.r + material.albedo.g + material.albedo.b) * 0.333;
                    material.metallic = 1.0;
                }

                // Polished blocks
                if(id == 10112) material.smoothness = (material.albedo.r + material.albedo.g + material.albedo.b) * 0.1998 + 0.4;
            
                // Packed ice
                if(id == 10065) material.smoothness = 0.96;
            #endif

            #ifdef WATER
                // Glass and ice
                if(id == 10064 || id == 10065) material.smoothness = 0.96;

                // Gelatin
                if(id == 10066) material.smoothness = 0.96;
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
