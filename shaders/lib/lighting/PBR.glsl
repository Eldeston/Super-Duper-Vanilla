uniform sampler2D texture;

void enviroPBR(inout matPBR material, in positionVectors posVector, in vec3 rawNorm, in vec3 dither){
    float puddle = texPix2DBicubic(noisetex, posVector.worldPos.xz / 256.0, vec2(256)).x;
    float rainMatFact = saturate(rainStrength * sqrt(rawNorm.y) * cubed(material.light_m.y) * smoothstep(0.25, 0.75, puddle));
    
    material.normal_m = mix(material.normal_m, rawNorm, rainMatFact);
    material.roughness_m = material.roughness_m * (1.0 - rainMatFact);
    material.albedo_t.rgb = material.albedo_t.rgb * (1.0 - rainMatFact * 0.8);
}

#ifdef AUTO_GEN_NORM
#endif

#if DEFAULT_MAT == 2
    uniform sampler2D normals;
    uniform sampler2D specular;

    void getPBR(inout matPBR material, positionVectors posVector, mat3 TBN, vec3 tint, vec2 st, int id){
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

        // Extract reflectance
        float reflectance = SRPSSE.g * 255.0;
        // Assign metallic
        material.metallic_m = reflectance <= 229 ? reflectance / 229.0 : 0.99;

        // Extact SS
        float PSS = SRPSSE.b * 255.0;
        // Assign SS
        material.ss_m = saturate((PSS - 64.0) / (255.0 - 64.0));

        // Assign emissive
        material.emissive_m = SRPSSE.a * float(SRPSSE.a != 1);

        // Assign ambient
        material.ambient_m = normalAOH.b;

        #if defined TERRAIN || defined WATER
            // If lava
            if(id == 10017){
                material.emissive_m = 1.0;
                material.roughness_m = 1.0;
                material.ambient_m = 1.0;
            }

            // If water
            if(id == 10034){
                material.roughness_m = 0.03;
                material.ambient_m = 1.0;
            }

            // End portal
            if(id == 10030){
                material.roughness_m = 0.0;
                material.emissive_m = 1.0;
            }
        #endif

        material.roughness_m = max(material.roughness_m, 0.03);
    }
#else
    void getPBR(inout matPBR material, in positionVectors posVector, in mat3 TBN, in vec3 tint, in vec2 st, in int id){
        // Assign default normal map
        material.normal_m = TBN[2];

        // Generate bumped normals
        #if (defined TERRAIN || defined WATER) && defined AUTO_GEN_NORM
            // Assign albedo
            material.albedo_t = texture2D(texture, mix(minTexCoord, maxTexCoord, st));

            // Square distance to center of the block
            float distCenter = max2(st - 0.5);

            // Don't generate normals if it's on the edge of the texture
            if(distCenter < 0.5 - 0.0125){
                float d = getLuminance(material.albedo_t.rgb);
                float dx = d - getLuminance(texture2D(texture, mix(minTexCoord, maxTexCoord, (st + vec2(0.0125, 0)))).rgb);
                float dy = d - getLuminance(texture2D(texture, mix(minTexCoord, maxTexCoord, (st + vec2(0, 0.0125)))).rgb);

                material.normal_m = normalize(TBN * normalize(vec3(dx, dy, 0.125)));
            }
        #else
            // Assign albedo
            material.albedo_t = texture2D(texture, st);
        #endif

        // Default material if not specified
        material.metallic_m = 0.0; material.emissive_m = 0.0;
        material.roughness_m = 1.0; material.ss_m = 0.0;
        material.ambient_m = 1.0;

        #if (defined TERRAIN || defined WATER) && DEFAULT_MAT == 1
            vec3 hsv = saturate(rgb2hsv(material.albedo_t));
            float maxCol = maxC(material.albedo_t.rgb);
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

        #if defined TERRAIN || defined WATER
            // If lava
            if(id == 10017){
                material.emissive_m = 1.0;
                material.roughness_m = 1.0;
                material.ambient_m = 1.0;
            }

            // If water
            if(id == 10034){
                material.metallic_m = 0.0;
                material.roughness_m = 0.03;
                material.ambient_m = 1.0;
            }
        #endif
        
        #if (defined TERRAIN || defined WATER) && DEFAULT_MAT == 1
            // Foliage and corals
            if(id >= 10000 && id <= 10008) material.ss_m = 0.8;

            // Emissives
            if(id == 10016 || id == 10017){
                material.emissive_m = smoothstep(0.5, 1.0, maxCol);
            }

            // Redstone
            if(id == 10018){
                material.emissive_m = cubed(material.albedo_t.r) * hsv.y;
                material.roughness_m = (1.0 - material.emissive_m);
                material.metallic_m = material.emissive_m;
            }

            // Glass and ice
            if(id == 10032 || id == 10033) material.roughness_m = 0.0;

            // Gem ores and blocks
            if(id == 10048 || id == 10050){
                material.roughness_m = cubed(1.0 - hsv.y);
                material.metallic_m = hsv.y * 0.6;
            }

            // Netherack gem ores
            if(id == 10049) material.roughness_m = material.albedo_t.r;

            // Metal ores
            if(id == 10064){
                material.roughness_m = squared(1.0 - hsv.y);
                material.metallic_m = smoothstep(0.1, 0.4, hsv.y);
            }

            // Netherack metal ores
            if(id == 10065){
                material.metallic_m = smoothstep(0.5, 0.75, max2(material.albedo_t.rg));;
                material.roughness_m = smoothstep(0.75, 0.5, max2(material.albedo_t.rg));;
            }

            // Metal blocks
            if(id == 10066){
                material.metallic_m = maxCol;
                material.roughness_m = 1.0 - maxCol;
            }

            // Dark metals
            if(id == 10067){
                material.metallic_m = sumCol;
                material.roughness_m = 1.0 - sumCol;
            }

            // Polished blocks
            if(id == 10080) material.roughness_m = 1.0 - sumCol;

            // End portal
            if(id == 10100){
                material.roughness_m = 0.0;
                material.emissive_m = 1.0;
            }
        #endif

        material.roughness_m = max(material.roughness_m, 0.03);
    }
#endif