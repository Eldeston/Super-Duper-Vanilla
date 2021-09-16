uniform sampler2D texture;

#ifdef AUTO_GEN_NORM
#endif

#if (defined TERRAIN || defined WATER || defined BLOCK) && defined ENVIRO_MAT
    uniform float isWarm;
    uniform float isSnowy;
    uniform float isPeaks;

    void enviroPBR(inout matPBR material, in positionVectors posVector, in vec3 rawNorm){
        float rainMatFact = rainStrength * (1.0 - isWarm) * (1.0 - isSnowy) * (1.0 - isPeaks);

        if(rainMatFact != 0){
            float puddle = texPix2DCubic(noisetex, posVector.worldPos.xz / 256.0, vec2(256)).x;
            rainMatFact *= saturate(sqrt(rawNorm.y) * cubed(material.light_m.y) * smoothstep(0.25, 0.75, puddle));
            
            material.normal_m = mix(material.normal_m, rawNorm, rainMatFact);
            material.roughness_m *= 1.0 - rainMatFact;
            material.metallic_m *= 1.0 - rainMatFact * 0.5;
            material.albedo_t *= 1.0 - rainMatFact * 0.5;
        }
    }
#endif

#if DEFAULT_MAT == 2
    uniform sampler2D normals;
    uniform sampler2D specular;

    void getPBR(inout matPBR material, in positionVectors posVector, in mat3 TBN, in vec3 tint, in vec2 st, in int id){
        // Assign default normal map
        material.normal_m = TBN[2];

        // Assign albedo
        material.albedo_t = texture2D(texture, st);

        #if WHITE_MODE == 0
            material.albedo_t.rgb *= tint;
        #elif WHITE_MODE == 1
            material.albedo_t.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo_t.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo_t.rgb = tint;
        #endif

        // Get raw textures
        vec4 normalAOH = texture2D(normals, st);
        vec4 SRPSSE = texture2D(specular, st);

        // Decode and extract the materials
        // Extract normals
        vec3 normalMap = normalAOH.xyz * 2.0 - 1.0;
        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
        // Assign normal
        material.normal_m = normalize(TBN * normalize(clamp(normalMap, -1.0, 1.0)));

        // Assign roughness
        material.roughness_m = pow(1.0 - SRPSSE.r, 2.0);

        // Assign reflectance
        material.metallic_m = SRPSSE.g;

        // Extact SS
        float PSS = SRPSSE.b * 255.0;
        // Assign SS
        material.ss_m = saturate((PSS - 64.0) / (255.0 - 64.0));

        // Assign emissive
        material.emissive_m = SRPSSE.a * float(SRPSSE.a != 1);

        // Assign ambient
        material.ambient_m = normalAOH.b;

        #if defined TERRAIN || defined WATER || defined BLOCK
            // If lava
            if(id == 10017){
                material.emissive_m = 1.0;
                material.roughness_m = 1.0;
                material.ambient_m = 1.0;
            }

            // If water
            if(id == 10034){
                material.roughness_m = 0.03;
                material.metallic_m = 0.02;
                material.ambient_m = 1.0;
            }

            // End portal
            if(id == 10100){
                material.albedo_t = vec4(1);
                material.roughness_m = 0.3;
                material.emissive_m = 1.0;
            }
            
            // Nether portal
            if(id == 10101){
                material.roughness_m = 0.3;
                material.emissive_m = maxC(material.albedo_t);
            }
        #endif

        material.roughness_m = max(material.roughness_m, 0.03);
    }
#else
    void getPBR(inout matPBR material, in positionVectors posVector, in mat3 TBN, in vec3 tint, in vec2 st, in int id){
        // Assign default normal map
        material.normal_m = TBN[2];

        // Generate bumped normals
        #if (defined TERRAIN || defined WATER || defined BLOCK) && defined AUTO_GEN_NORM
            // Assign albedo
            material.albedo_t = texture2D(texture, mix(minTexCoord, maxTexCoord, st));

            // Square distance to center of the block
            float distCenter = max2(st - 0.5);

            // Don't generate normals if it's on the edge of the texture
            if(distCenter < 0.5 - 0.0125){
                float d = getLuminance(material.albedo_t.rgb);
                float dx = d - getLuminance(texture2D(texture, mix(minTexCoord, maxTexCoord, (st + vec2(0.0125, 0)))).rgb);
                float dy = d - getLuminance(texture2D(texture, mix(minTexCoord, maxTexCoord, (st + vec2(0, 0.0125)))).rgb);

                material.normal_m = normalize(TBN * normalize(vec3(dx, dy, 0.128)));
            }
        #else
            // Assign albedo
            material.albedo_t = texture2D(texture, st);
        #endif

        // Default material if not specified
        material.metallic_m = 0.0; material.emissive_m = 0.0;
        material.roughness_m = 1.0; material.ss_m = 0.0;
        material.ambient_m = 1.0;

        #if (defined TERRAIN || defined WATER || defined BLOCK) && DEFAULT_MAT == 1
            vec3 hsv = saturate(rgb2hsv(material.albedo_t));
            float sumCol = saturate(material.albedo_t.r + material.albedo_t.g + material.albedo_t.b);
        #endif

        #if WHITE_MODE == 0
            material.albedo_t.rgb *= tint;
        #elif WHITE_MODE == 1
            material.albedo_t.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo_t.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo_t.rgb = tint;
        #endif

        #if defined TERRAIN || defined WATER || defined BLOCK
            // If lava
            if(id == 10017) material.emissive_m = 1.0;

            // If water
            if(id == 10034){
                material.roughness_m = 0.03;
                material.metallic_m = 0.02;
            }

            // End portal
            if(id == 10100){
                material.albedo_t = vec4(1);
                material.roughness_m = 0.3;
                material.emissive_m = maxC(material.albedo_t);
            }
            
            // Nether portal
            if(id == 10101){
                material.roughness_m = 0.3;
                material.emissive_m = hsv.z;
            }
        #endif
        
        #if (defined TERRAIN || defined WATER || defined BLOCK) && DEFAULT_MAT == 1
            // Foliage and corals
            if((id >= 10000 && id <= 10008) || id == 10013) material.ss_m = 0.8;

            // Glow berries
            if(id == 10012){
                material.ss_m = 0.8;
                material.emissive_m = max2(material.albedo_t.rg) > 0.8 ? 0.72 : material.emissive_m;
            }

            // Stems
            if(id == 10009) material.emissive_m = material.albedo_t.r < 0.1 ? hsv.z * 0.72 : material.emissive_m;
            if(id == 10010) material.emissive_m = material.albedo_t.b < 0.16 && material.albedo_t.r > 0.4 ? hsv.z * 0.72 : material.emissive_m;

            // Fungus
            if(id == 10011) material.emissive_m = max2(material.albedo_t.rg) > 0.8 ? 0.72 : material.emissive_m;

            // Emissives
            if(id == 10016 || id == 10017) material.emissive_m = smoothstep(0.6, 0.8, hsv.z);

            // Redstone
            if(id == 10018 || id == 10068){
                material.emissive_m = cubed(material.albedo_t.r) * hsv.y;
                material.roughness_m = (1.0 - material.emissive_m);
                material.metallic_m = step(0.8, material.emissive_m);
            }

            // Glass and ice
            if(id == 10032 || id == 10033) material.roughness_m = 0.03;

            // Slime and honey
            if(id == 10035) material.roughness_m = 0.03;

            // Gem ores
            if(id == 10048){
                material.roughness_m = hsv.y > 0.128 ? 0.06 : material.roughness_m;
                material.metallic_m = hsv.y > 0.128 ? 0.17 : material.metallic_m;
            }

            // Gem blocks
            if(id == 10050){
                material.roughness_m = 0.03;
                material.metallic_m = 0.17;
            }

            // Netherack gem ores
            if(id == 10049){
                material.roughness_m = hsv.y < 0.256 ? 0.06 : material.roughness_m;
                material.metallic_m = hsv.y < 0.256 ? 0.17 : material.metallic_m;
            }

            // Metal ores
            if(id == 10064){
                material.roughness_m = hsv.y > 0.128 ? 0.06 : material.roughness_m;
                material.metallic_m = hsv.y > 0.128 ? 1.0 : material.metallic_m;
            }

            // Netherack metal ores
            if(id == 10065){
                material.roughness_m = max2(material.albedo_t.rg) > 0.6 ? 0.06 : material.roughness_m;
                material.metallic_m = max2(material.albedo_t.rg) > 0.6 ? 1.0 : material.metallic_m;
            }

            // Metal blocks
            if(id == 10066){
                material.roughness_m = 1.0 - hsv.z;
                material.metallic_m = 1.0;
            }

            // Dark metals
            if(id == 10067){
                material.roughness_m = 1.0 - sumCol;
                material.metallic_m = 1.0;
            }

            // Rails
            if(id == 10068){
                material.roughness_m = hsv.y < 0.128 ? 0.03 : material.roughness_m;
                material.metallic_m = hsv.y < 0.128 ? 1.0 : material.metallic_m;
            }

            // Polished blocks
            if(id == 10080) material.roughness_m = 1.0 - sumCol;
        #endif

        material.roughness_m = max(material.roughness_m, 0.03);
    }
#endif