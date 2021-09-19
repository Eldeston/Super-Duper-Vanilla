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
            rainMatFact *= saturate(sqrt(rawNorm.y) * cubed(material.light.y) * smoothstep(0.25, 0.75, puddle));
            
            material.normal = mix(material.normal, rawNorm, rainMatFact);
            material.smoothness = mix(material.smoothness, 1.0, rainMatFact);
            material.albedo *= 1.0 - rainMatFact * 0.5;
        }
    }
#endif

#if DEFAULT_MAT == 2
    uniform sampler2D normals;
    uniform sampler2D specular;

    void getPBR(inout matPBR material, in positionVectors posVector, in mat3 TBN, in vec3 tint, in vec2 st, in int id){
        // Assign default normal map
        material.normal = TBN[2];

        // Assign albedo
        material.albedo = texture2D(texture, st);

        #if WHITE_MODE == 0
            material.albedo.rgb *= tint;
        #elif WHITE_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo.rgb = tint;
        #endif

        // Get raw textures
        vec4 normalAOH = texture2D(normals, st);
        vec4 SRPSSE = texture2D(specular, st);

        // Decode and extract the materials
        // Extract normals
        vec3 normalMap = normalAOH.xyz * 2.0 - 1.0;
        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
        // Assign normal
        material.normal = normalize(TBN * normalize(clamp(normalMap, vec3(-1), vec3(1))));

        // Assign smoothness
        material.smoothness = SRPSSE.r;

        // Assign reflectance
        material.metallic = SRPSSE.g;

        // Extact SS
        float PSS = SRPSSE.b * 255.0;
        // Assign SS
        material.ss = saturate((PSS - 64.0) / (255.0 - 64.0));

        // Assign emissive
        material.emissive = SRPSSE.a * float(SRPSSE.a != 1);

        // Assign ambient
        material.ambient = normalAOH.b;

        #if defined TERRAIN || defined WATER || defined BLOCK
            // If lava
            if(id == 10017){
                material.emissive = 1.0;
                material.smoothness = 0.0;
                material.ambient = 1.0;
            }

            // If water
            if(id == 10034){
                material.smoothness = 0.95;
                material.metallic = 0.02;
                material.ambient = 1.0;
            }

            // End portal
            if(id == 10100){
                material.albedo = vec4(1);
                material.smoothness = 0.95;
                material.emissive = 1.0;
            }
            
            // Nether portal
            if(id == 10101){
                material.smoothness = 0.95;
                material.emissive = maxC(material.albedo.rgb);
            }
        #endif

        material.smoothness = min(material.smoothness, 0.95);
    }
#else
    void getPBR(inout matPBR material, in positionVectors posVector, in mat3 TBN, in vec3 tint, in vec2 st, in int id){
        // Assign default normal map
        material.normal = TBN[2];

        // Generate bumped normals
        #if (defined TERRAIN || defined WATER || defined BLOCK) && defined AUTO_GEN_NORM
            // Assign albedo
            material.albedo = texture2D(texture, mix(minTexCoord, maxTexCoord, st));

            // Square distance to center of the block
            float distCenter = max2(st - 0.5);

            // Don't generate normals if it's on the edge of the texture
            if(distCenter < 0.5 - 0.0125){
                float d = getLuminance(material.albedo.rgb);
                float dx = d - getLuminance(texture2D(texture, mix(minTexCoord, maxTexCoord, (st + vec2(0.0125, 0)))).rgb);
                float dy = d - getLuminance(texture2D(texture, mix(minTexCoord, maxTexCoord, (st + vec2(0, 0.0125)))).rgb);

                material.normal = normalize(TBN * normalize(vec3(dx, dy, 0.128)));
            }
        #else
            // Assign albedo
            material.albedo = texture2D(texture, st);
        #endif

        // Default material if not specified
        material.metallic = 0.0; material.emissive = 0.0;
        material.smoothness = 0.0; material.ss = 0.0;
        material.ambient = 1.0;

        #if (defined TERRAIN || defined WATER || defined BLOCK) && DEFAULT_MAT == 1
            vec3 hsv = saturate(rgb2hsv(material.albedo));
            float sumCol = saturate(material.albedo.r + material.albedo.g + material.albedo.b);
        #endif

        #if WHITE_MODE == 0
            material.albedo.rgb *= tint;
        #elif WHITE_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            material.albedo.rgb = tint;
        #endif

        #if defined TERRAIN || defined WATER || defined BLOCK
            // If lava
            if(id == 10017) material.emissive = 1.0;

            // If water
            if(id == 10034){
                material.smoothness = 0.95;
                material.metallic = 0.02;
            }

            // End portal
            if(id == 10100){
                material.albedo = vec4(1);
                material.smoothness = 0.95;
                material.emissive = maxC(material.albedo);
            }
            
            // Nether portal
            if(id == 10101){
                material.smoothness = 0.95;
                material.emissive = maxC(material.albedo.rgb);
            }
        #endif
        
        #if (defined TERRAIN || defined WATER || defined BLOCK) && DEFAULT_MAT == 1
            // Foliage and corals
            if((id >= 10000 && id <= 10008) || id == 10013) material.ss = 0.8;

            // Glow berries
            if(id == 10012){
                material.ss = 0.8;
                material.emissive = max2(material.albedo.rg) > 0.8 ? 0.72 : material.emissive;
            }

            // Stems
            if(id == 10009) material.emissive = material.albedo.r < 0.1 ? hsv.z * 0.72 : material.emissive;
            if(id == 10010) material.emissive = material.albedo.b < 0.16 && material.albedo.r > 0.4 ? hsv.z * 0.72 : material.emissive;

            // Fungus
            if(id == 10011) material.emissive = max2(material.albedo.rg) > 0.8 ? 0.72 : material.emissive;

            // Emissives
            if(id == 10016 || id == 10017) material.emissive = smoothstep(0.6, 0.8, hsv.z);

            // Redstone
            if(id == 10018 || id == 10068){
                material.emissive = cubed(material.albedo.r) * hsv.y;
                material.smoothness = material.emissive;
                material.metallic = step(0.8, material.emissive);
            }

            // Glass and ice
            if(id == 10032 || id == 10033) material.smoothness = 0.95;

            // Slime and honey
            if(id == 10035) material.smoothness = 0.95;

            // Gem ores
            if(id == 10048){
                material.smoothness = hsv.y > 0.128 ? 0.925 : material.smoothness;
                material.metallic = hsv.y > 0.128 ? 0.17 : material.metallic;
            }

            // Gem blocks
            if(id == 10050){
                material.smoothness = 0.95;
                material.metallic = 0.17;
            }

            // Netherack gem ores
            if(id == 10049){
                material.smoothness = hsv.y < 0.256 ? 0.925 : material.smoothness;
                material.metallic = hsv.y < 0.256 ? 0.17 : material.metallic;
            }

            // Metal ores
            if(id == 10064){
                material.smoothness = hsv.y > 0.128 ? 0.925 : material.smoothness;
                material.metallic = hsv.y > 0.128 ? 1.0 : material.metallic;
            }

            // Netherack metal ores
            if(id == 10065){
                material.smoothness = max2(material.albedo.rg) > 0.6 ? 0.925 : material.smoothness;
                material.metallic = max2(material.albedo.rg) > 0.6 ? 1.0 : material.metallic;
            }

            // Metal blocks
            if(id == 10066){
                material.smoothness = hsv.z;
                material.metallic = 1.0;
            }

            // Dark metals
            if(id == 10067){
                material.smoothness = sumCol;
                material.metallic = 1.0;
            }

            // Rails
            if(id == 10068){
                material.smoothness = hsv.y < 0.128 ? 0.95 : material.smoothness;
                material.metallic = hsv.y < 0.128 ? 1.0 : material.metallic;
            }

            // Polished blocks
            if(id == 10080) material.smoothness = sumCol;
        #endif

        material.smoothness = min(material.smoothness, 0.95);
    }
#endif