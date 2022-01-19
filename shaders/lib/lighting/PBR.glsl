uniform sampler2D texture;

#ifdef AUTO_GEN_NORM
#endif

#if (defined TERRAIN || defined WATER || defined BLOCK) && defined ENVIRO_MAT
    uniform float isWarm;
    uniform float isSnowy;
    uniform float isPeaks;

    void enviroPBR(inout matPBR material, in vec3 worldPos, in vec3 rawNorm){
        float rainMatFact = sqrt(max(0.0, rawNorm.y)) * smoothstep(0.8, 0.9, material.light.y) * rainStrength * (1.0 - isWarm) * (1.0 - isSnowy) * (1.0 - isPeaks);

        if(rainMatFact != 0){
            vec3 noiseData = texPix2DCubic(noisetex, worldPos.xz / 512.0, vec2(256)).xyz;
            rainMatFact *= smoothstep(0.4, 0.8, (mix(noiseData.y, noiseData.x, noiseData.z) + noiseData.y) * 0.5);
            
            material.normal = mix(material.normal, rawNorm, rainMatFact);
            material.metallic = max(0.04 * rainMatFact, material.metallic);
            material.smoothness = mix(material.smoothness, 0.96, rainMatFact);
            material.albedo.rgb *= 1.0 - sqrt(rainMatFact) * 0.25;
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

        if(material.albedo.a > 0.00001){
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
                // Foliage and corals
                if((id >= 10000 && id <= 10008) || (id >= 10011 && id <= 10013)) material.ss = 0.8;
                
                // If lava
                if(id == 10017) material.emissive = 1.0;

                // If water
                else if(id == 10034){
                    material.smoothness = 0.96;
                    material.metallic = 0.04;
                }

                // End portal
                else if(id == 10100){
                    vec3 d0 = texture2D(texture, (posVector.screenPos.yx + vec2(0, frameTimeCounter * 0.02)) * 0.5).rgb;
                    vec3 d1 = texture2D(texture, (posVector.screenPos.yx + vec2(0, frameTimeCounter * 0.01))).rgb;
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
                material.albedo.rgb *= tint;
            #elif WHITE_MODE == 1
                material.albedo.rgb = vec3(1);
            #elif WHITE_MODE == 2
                material.albedo.rgb = vec3(0);
            #elif WHITE_MODE == 3
                material.albedo.rgb = tint;
            #endif

            material.smoothness = min(material.smoothness, 0.96);
        }
    }
#else
    void getPBR(inout matPBR material, in positionVectors posVector, in mat3 TBN, in vec3 tint, in vec2 st, in int id){
        // Assign default normal map
        material.normal = TBN[2];

        // Generate bumped normals
        #if (defined TERRAIN || defined WATER || defined BLOCK) && defined AUTO_GEN_NORM
            // Assign albedo
            material.albedo = texture2D(texture, mix(minTexCoord, maxTexCoord, st));

            // Don't generate normals if it's on the edge of the texture
            if(max2(st - 0.5) < 0.5 - 0.0125){
                float d = length(material.albedo.rgb);
                float dx = d - length(texture2D(texture, mix(minTexCoord, maxTexCoord, (st + vec2(0.0125, 0)))).rgb);
                float dy = d - length(texture2D(texture, mix(minTexCoord, maxTexCoord, (st + vec2(0, 0.0125)))).rgb);

                material.normal = normalize(TBN * normalize(vec3(vec2(dx, dy) / 0.125, 2)));
            }
        #else
            // Assign albedo
            material.albedo = texture2D(texture, st);
        #endif

        if(material.albedo.a > 0.00001){
            // Default material if not specified
            material.metallic = 0.04; material.emissive = 0.0;
            material.smoothness = 0.0; material.ss = 0.0;
            material.ambient = 1.0;

            #if (defined TERRAIN || defined WATER || defined BLOCK) && DEFAULT_MAT == 1
                vec3 hsv = saturate(rgb2hsv(material.albedo));
                float sumCol = saturate(material.albedo.r + material.albedo.g + material.albedo.b);
            #endif

            #if defined TERRAIN || defined WATER || defined BLOCK
                // Foliage and corals
                if((id >= 10000 && id <= 10008) || (id >= 10011 && id <= 10013)) material.ss = 0.8;

                // If lava
                if(id == 10017) material.emissive = 1.0;

                // If water
                else if(id == 10034){
                    material.smoothness = 0.96;
                }

                // End portal
                else if(id == 10100){
                    vec3 d0 = texture2D(texture, posVector.screenPos.yx + vec2(0, frameTimeCounter * 0.01)).rgb;
                    vec3 d1 = texture2D(texture, posVector.screenPos.yx * 1.25 + vec2(0, frameTimeCounter * 0.01)).rgb;
                    material.albedo = vec4(d0 + d1 + 0.05, 1);
                    material.normal = TBN[2];
                    material.smoothness = 0.96;
                    material.emissive = 1.0;
                }
                
                // Nether portal
                else if(id == 10101){
                    material.smoothness = 0.96;
                    material.emissive = maxC(material.albedo.rgb);
                }
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
            
            #if (defined TERRAIN || defined WATER || defined BLOCK) && DEFAULT_MAT == 1
                // Glow berries
                else if(id == 10012){
                    material.emissive = max2(material.albedo.rg) > 0.8 ? 0.72 : material.emissive;
                }

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

                // Glass and ice
                else if(id == 10032 || id == 10033) material.smoothness = 0.96;

                // Slime and honey
                else if(id == 10035) material.smoothness = 0.96;

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
                    material.metallic = hsv.y < 0.256 ? 0.17 : material.metallic;
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

            material.smoothness = min(material.smoothness, 0.96);
        }
    }
#endif