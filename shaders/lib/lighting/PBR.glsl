#extension GL_ARB_shader_texture_lod : enable

#define slopeNormalStrength 0.024
#define softShadowStrength 60.0
#define pomSamplesMin 4

// Derivatives
vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);

uniform sampler2D texture;

#ifdef AUTO_GEN_NORM
#endif

#if (defined TERRAIN || defined WATER || defined BLOCK) && defined ENVIRO_MAT
    uniform float isWarm;
    uniform float isSnowy;
    uniform float isPeaks;
    uniform float wetness;

    void enviroPBR(inout matPBR material, in vec3 worldPos){
        float rainMatFact = sqrt(max(0.0, TBN[2].y)) * smoothstep(0.8, 0.9, material.light.y) * wetness * (1.0 - isWarm) * (1.0 - isSnowy) * (1.0 - isPeaks);

        if(rainMatFact != 0){
            vec3 noiseData = texPix2DCubic(noisetex, worldPos.xz / 512.0, vec2(256)).xyz;
            rainMatFact *= smoothstep(0.4, 0.8, (mix(noiseData.y, noiseData.x, noiseData.z) + noiseData.y) * 0.5);
            
            material.normal = mix(material.normal, TBN[2], rainMatFact);
            material.metallic = max(0.02 * rainMatFact, material.metallic);
            material.smoothness = mix(material.smoothness, 0.96, rainMatFact);
            material.albedo.rgb *= 1.0 - sqrt(rainMatFact) * 0.25;
        }
    }
#endif

// Gets the actual texCoord
#define GET_TEXCOORD(TEXCOORD) fract(TEXCOORD) * vTexCoordScale + vTexCoordPos

#if DEFAULT_MAT == 2
    uniform sampler2D normals;
    uniform sampler2D specular;

    // This is for Optifine to detect the option...
    #ifdef PARALLAX_OCCLUSION
    #endif

    #if (defined TERRAIN || defined WATER || defined BLOCK || defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER) && defined PARALLAX_OCCLUSION
        float lengthSq(vec3 vec) {return dot(vec, vec);}
        float pow2(float val) {return val*val;}
        
        vec2 getParallaxOffset(in vec3 dirT)
        {
            float length = sqrt(lengthSq(dirT) - pow2(dirT.z)) / dirT.z;
            return length * normalize(dirT.xy);
        }

        vec2 parallaxUv(vec2 startUv, vec2 endUv, float NoV, out vec3 tracePos, out float texDepth) {
            float stepSize = 1.0 / PARALLAX_STEPS;
            endUv *= stepSize * PARALLAX_DEPTH;

            texDepth = texture2DGradARB(normals, fract(startUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;
            float traceDepth = 1.0;

            for (int step = 0; step < PARALLAX_STEPS; step++) {
                startUv += endUv;
                traceDepth -= stepSize;
                texDepth = texture2DGradARB(normals, fract(startUv) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;

                if (texDepth - traceDepth > 0.00001) break;
            }

            tracePos = vec3(startUv - endUv, traceDepth + stepSize);
            return startUv;
        }

        float parallaxShadow(in vec3 tracePos, in vec2 lightOffset) {
            float stepSize = 1.0 / PARALLAX_STEPS;
            vec2 stepOffset = stepSize * lightOffset;
            
            float traceDepth = tracePos.z;
            vec2 trace_tex = tracePos.xy;

            float result = 0.0;
            for (int step = int(traceDepth * PARALLAX_STEPS); step < PARALLAX_STEPS; ++step) {
                trace_tex += stepOffset;
                traceDepth += stepSize;

                float texDepth = texture2DGradARB(normals, fract(trace_tex) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).a;
                float h = texDepth - traceDepth;
                
                if (h > 0.0) {
                    float dist = 1.0 + lengthSq(vec3(trace_tex, traceDepth) - vec3(tracePos.xy, 1.0)) * 20.0;

                    float sampleResult = saturate(h * softShadowStrength * (1.0 / dist));
                    result = max(result, sampleResult);
                    if (1.0 - result < 0.00001) break;
                }
            }

            return 1.0 - result;
        }

        vec3 apply_slope_normal(in vec3 viewT, in vec2 tex, in float trace_depth) {
            vec2 tex_size = textureSize(normals, 0);
            vec2 pixel_size = 1.0 / tex_size;

            vec2 tex_snapped = floor(tex * tex_size) * pixel_size;
            vec2 tex_offset = tex - tex_snapped - 0.5 * pixel_size;
            vec2 step_sign = sign(-viewT.xy);

            vec2 tex_x = tex_snapped + vec2(pixel_size.x * step_sign.x, 0.0);
            float height_x = texture2DGradARB(normals, tex_x, dcdx, dcdy).a;
            bool has_x = trace_depth > height_x && sign(tex_offset.x) == step_sign.x;

            vec2 tex_y = tex_snapped + vec2(0.0, pixel_size.y * step_sign.y);
            float height_y = texture2DGradARB(normals, tex_y, dcdx, dcdy).a;
            bool has_y = trace_depth > height_y && sign(tex_offset.y) == step_sign.y;

            if (abs(tex_offset.x) < abs(tex_offset.y)) {
                if (has_y) return vec3(0.0, step_sign.y, 0.0);
                if (has_x) return vec3(step_sign.x, 0.0, 0.0);
            }
            else {
                if (has_x) return vec3(step_sign.x, 0.0, 0.0);
                if (has_y) return vec3(0.0, step_sign.y, 0.0);
            }

            float s = step(abs(viewT.y), abs(viewT.x));
            return vec3(vec2(1.0 - s, s) * step_sign, 0.0);
        }
    #endif

    void getPBR(inout matPBR material, in positionVectors posVector, in int id){
        // Assign default normal map
        material.normal = TBN[2];

        vec3 viewDir = normalize(-posVector.eyePlayerPos);
        vec2 st = texCoord;
        float texDepth;
        vec3 tracePos;
        vec2 puv;

        #if (defined TERRAIN || defined WATER || defined BLOCK || defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER) && defined PARALLAX_OCCLUSION
            // Exclude signs, due to a missing text bug
            if (id != 10102) {
                float NoV = saturate(dot(material.normal, viewDir));

                vec3 endPos = viewDir * TBN;
                puv = parallaxUv(vTexCoord, endPos.xy / -endPos.z, NoV, tracePos, texDepth);
                st = fract(puv) * vTexCoordScale + vTexCoordPos;
            }
        #endif

        // Assign albedo
        material.albedo = texture2DGradARB(texture, st, dcdx, dcdy);
        if (material.albedo.a <= 0.00001) return;
        
        material.smoothness = min(material.smoothness, 0.96);
    }
#else
    void getPBR(inout matPBR material, in positionVectors posVector, in int id){
        // Assign default normal map
        material.normal = TBN[2];

        vec2 st = texCoord;

        // Assign albedo
        material.albedo = texture2DGradARB(texture, st, dcdx, dcdy);

        // Alpha check, exit immediately
        if(material.albedo.a <= 0.00001) return;

        // Generate bumped normals
        #if (defined TERRAIN || defined WATER || defined BLOCK || defined ENTITIES || defined HAND || defined ENTITIES_GLOWING || defined HAND_WATER) && defined AUTO_GEN_NORM
            float d = length(material.albedo.rgb);
            float dx = d - length(texture2DGradARB(texture, fract(vTexCoord + vec2(0.0125, 0)) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);
            float dy = d - length(texture2DGradARB(texture, fract(vTexCoord + vec2(0, 0.0125)) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);

            material.normal = normalize(TBN * normalize(vec3(dx, dy, 0.125)));
        #endif

        // Default material if not specified
        material.metallic = 0.04; material.emissive = 0.0;
        material.smoothness = 0.0; material.ss = 0.0;
        material.ambient = glcolor.a; material.parallaxShd = 1.0;

        #if (defined TERRAIN || defined WATER || defined BLOCK) && DEFAULT_MAT == 1
            vec3 hsv = saturate(rgb2hsv(material.albedo));
            float sumCol = saturate(material.albedo.r + material.albedo.g + material.albedo.b);
        #endif

        #if defined TERRAIN || defined BLOCK
            // Foliage and corals
            if((id >= 10000 && id <= 10008) || (id >= 10011 && id <= 10013)) material.ss = 1.0;

            // If lava
            else if(id == 10017) material.emissive = 1.0;
        #endif

        #if defined WATER || defined BLOCK
            // If water
            if(id == 10034){
                material.smoothness = 0.96;
                material.metallic = 0.02;
            }

            // End portal
            else if(id == 10100){
                vec3 d0 = texture2DGradARB(texture, (posVector.screenPos.yx + vec2(0, frameTimeCounter * 0.02)) * 0.5, dcdx, dcdy).rgb;
                vec3 d1 = texture2DGradARB(texture, (posVector.screenPos.yx + vec2(0, frameTimeCounter * 0.01)), dcdx, dcdy).rgb;
                material.albedo = vec4(d0 + d1 + 0.05, 1);
                material.normal = TBN[2];
                material.smoothness = 0.96;
                material.metallic = 0.04;
                material.emissive = 1.0;
            }
                
            // Nether portal
            else if(id == 10101){
                material.smoothness = 0.96;
                material.metallic = 0.04;
                material.emissive = maxC(material.albedo.rgb);
            }
        #endif

        #if WHITE_MODE == 0
            material.albedo.rgb *= glcolor.rgb;
        #elif WHITE_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo.rgb = glcolor.rgb;
        #endif

        #if DEFAULT_MAT == 1
            #if defined TERRAIN || defined BLOCK
                // Glow berries
                if(id == 10012) material.emissive = max2(material.albedo.rg) > 0.8 ? 0.72 : material.emissive;

                // Stems
                else if(id == 10009) material.emissive = material.albedo.r < 0.1 ? hsv.z * 0.72 : material.emissive;
                else if(id == 10010) material.emissive = material.albedo.b < 0.16 && material.albedo.r > 0.4 ? hsv.z * 0.72 : material.emissive;

                // Fungus
                else if(id == 10011) material.emissive = max2(material.albedo.rg) > 0.8 ? 0.72 : material.emissive;

                // Emissives
                else if(id == 10016 || id == 10017) material.emissive = smoothstep(0.6, 0.8, hsv.z);

                // Redstone
                else if(id == 10018 || id == 10068){
                    material.emissive = cubed(material.albedo.r) * hsv.y;
                    material.smoothness = material.emissive;
                    material.metallic = step(0.8, material.emissive);
                }

                // Gem ores
                else if(id == 10048){
                    material.smoothness = hsv.y > 0.128 ? 0.93 : material.smoothness;
                    material.metallic = hsv.y > 0.128 ? 0.17 : material.metallic;
                }

                // Gem blocks
                else if(id == 10050){
                    material.smoothness = 0.96;
                    material.metallic = 0.17;
                }

                // Netherack gem ores
                else if(id == 10049){
                    material.smoothness = hsv.y < 0.256 ? 0.93 : material.smoothness;
                    material.metallic = hsv.y < 0.256 ? 0.16 : material.metallic;
                }

                // Metal ores
                else if(id == 10064){
                    material.smoothness = hsv.y > 0.128 ? 0.93 : material.smoothness;
                    material.metallic = hsv.y > 0.128 ? 1.0 : material.metallic;
                }

                // Netherack metal ores
                else if(id == 10065){
                    material.smoothness = max2(material.albedo.rg) > 0.6 ? 0.93 : material.smoothness;
                    material.metallic = max2(material.albedo.rg) > 0.6 ? 1.0 : material.metallic;
                }

                // Metal blocks
                else if(id == 10066){
                    material.smoothness = hsv.z * hsv.z;
                    material.metallic = 1.0;
                }

                // Dark metals
                else if(id == 10067){
                    material.smoothness = sumCol;
                    material.metallic = 1.0;
                }

                // Rails
                else if(id == 10068){
                    material.smoothness = hsv.y < 0.128 ? 0.96 : material.smoothness;
                    material.metallic = hsv.y < 0.128 ? 1.0 : material.metallic;
                }

                // Polished blocks
                else if(id == 10080) material.smoothness = sumCol;
            #endif

            #if defined WATER || defined BLOCK
                // Glass and ice
                if(id == 10032 || id == 10033) material.smoothness = 0.96;

                // Slime and honey
                else if(id == 10035) material.smoothness = 0.96;
            #endif
        #endif

        material.smoothness = min(material.smoothness, 0.96);
    }
#endif