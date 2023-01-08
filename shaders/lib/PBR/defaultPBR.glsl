#ifdef AUTO_GEN_NORM
#endif

// The default PBR calculation
void getPBR(inout structPBR material, in int id){
    // Assign albedo
    material.albedo = textureGrad(tex, texCoord, dcdx, dcdy);

    #if !(defined ENTITIES || defined ENTITIES_GLOWING)
        // Alpha test, discard immediately
        if(material.albedo.a <= ALPHA_THRESHOLD) discard;
    #endif

    // Assign default normal map
    material.normal = TBN[2];

    // Generate bumped normals
    #if (defined TERRAIN || defined WATER || defined BLOCK) && defined AUTO_GEN_NORM
        if(id != 10015 && id != 10016 && id != 10022){
            const float autoGenNormPixSize = 2.0 / AUTO_GEN_NORM_RES;
            vec2 texCoordPixCenter = vTexCoord - autoGenNormPixSize * 0.5;

            float d0 = sumOf(textureGrad(tex, fract(texCoordPixCenter) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);
            float d1 = sumOf(textureGrad(tex, fract(vec2(texCoordPixCenter.x + autoGenNormPixSize, texCoordPixCenter.y)) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);
            float d2 = sumOf(textureGrad(tex, fract(vec2(texCoordPixCenter.x, texCoordPixCenter.y + autoGenNormPixSize)) * vTexCoordScale + vTexCoordPos, dcdx, dcdy).rgb);

            vec2 difference = d0 - vec2(d1, d2);
            // TBN * fastNormalize(vec3(difference, 1))
            material.normal = TBN * (vec3(difference, 1) * inversesqrt(lengthSquared(difference) + 1.0));

            // Calculate normal strength
            material.normal = mix(TBN[2], material.normal, NORMAL_STRENGTH);
        }
    #endif

    // Default material if not specified
    material.smoothness = 0.0; material.emissive = 0.0;
    material.metallic = 0.04; material.porosity = 0.0;
    material.ss = 0.0; material.parallaxShd = 1.0;

    #ifdef TERRAIN
        // Apply vanilla AO with it in terrain
        material.ambient = vertexAO;
    #else
        // For others, don't use vanilla AO
        material.ambient = 1.0;
    #endif

    #ifdef TERRAIN
        // If lava and fire
        if(id == 10000 || id == 10016) material.emissive = 1.0;

        // Foliage and corals
        else if((id >= 10001 && id <= 10014) || id == 10033 || id == 10036) material.ss = 1.0;
    #endif

    #ifdef WATER
        // If water
        if(id == 10015){
            material.smoothness = 0.96;
            material.metallic = 0.02;

            #ifdef WATER_FLAT
                material.albedo.rgb = vec3(0.8);
            #endif
        }

        // Nether portal
        else if(id == 10021){
            material.smoothness = 0.96;
            material.emissive = maxOf(material.albedo.rgb);
        }
    #endif

    #if defined ENTITIES || defined ENTITIES_GLOWING
        // Experience orbs, glowing item frames, and fireballs
        if(id == 10130 || id == 10131) material.emissive = cubed(sumOf(material.albedo.rgb) * 0.33333333);
    #endif

    #if PBR_MODE == 1
        #ifdef TERRAIN
            // Glow lichen
            if(id == 10032) material.emissive = material.albedo.r > material.albedo.b ? 1.0 : 0.0;

            // Glow berries
            else if(id == 10033) material.emissive = material.albedo.r + material.albedo.g > material.albedo.g * 2.0 ? smoothstep(0.3, 0.9, maxOf(material.albedo.rgb)) : material.emissive;

            // Stems
            else if(id == 10034) material.emissive = material.albedo.r < 0.1 ? maxOf(material.albedo.rgb) * 0.72 : material.emissive;
            else if(id == 10035) material.emissive = material.albedo.b < 0.16 && material.albedo.r > 0.4 ? maxOf(material.albedo.rgb) * 0.72 : material.emissive;

            // Fungus
            else if(id == 10036) material.emissive = float(sumOf(material.albedo.rg) > 1);

            // Chorus
            else if(id == 10037) material.emissive = float(sumOf(material.albedo.rg) > 1.1);
            else if(id == 10038) material.emissive = exp(sumOf(material.albedo.gb) * 8.0 - 16.0);

            // Reflective light emitting blocks and redstone lamps
            else if(id == 10048){
                material.emissive = saturate(sumOf(material.albedo.rgb) * 1.33333332 - 2.0);
                material.smoothness = 0.9;
            }

            // Frog lights
            else if(id == 10049){
                material.emissive = cubed(max(0.0, sumOf(material.albedo.rgb) * 1.33333332 - 3.0));
                material.smoothness = 0.9;
            }
                
            // Light emitting blocks
            else if(id == 10050 || id == 10051) material.emissive = squared(squared(saturate(sumOf(material.albedo.rgb) * 0.83333333 - 1)));
            else if(id == 10052) material.emissive = smoothen(max(0.0, maxOf(material.albedo.rgb) - 0.75) * 4.0);
            else if(id == 10053) material.emissive = exp(sumOf(material.albedo.rgb) * 2.66666664 - 8.0);

            // Sculk
            else if(id == 10057){
                material.emissive = cubed(max(0.0, material.albedo.b - material.albedo.r));
                material.smoothness = 0.6;
            }

            // Redstone stuff
            else if(id == 10054 || id == 10100){
                if(material.albedo.r > material.albedo.b * 2.4){
                    material.emissive = float(material.albedo.r > 0.5);
                    material.smoothness = 0.9;
                    material.metallic = 1.0;
                }
            }

            // Redstone block
            else if(id == 10055){
                material.emissive = 0.45;
                material.smoothness = 0.9 * material.albedo.r;
                material.metallic = 1.0;
            }

            // End portal frame
            else if(id == 10056) material.emissive = material.albedo.g + material.albedo.b > material.albedo.r * 2.0 ? squared(saturate((material.albedo.g - material.albedo.b) * 4.0)) : 0.0;

            // Gem ores
            else if(id == 10080 && (material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b)){
                float gemOreColSum = sumOf(material.albedo.rgb);
                if(gemOreColSum > 0.75){
                    material.smoothness = min(0.93, gemOreColSum);
                    material.metallic = 0.17;
                }
            }

            // Gem blocks
            else if(id == 10082){
                material.smoothness = fastSqrt(min(0.8, sumOf(material.albedo.rgb)));
                material.metallic = 0.17;
            }

            // Crying obsidian
            else if(id == 10083){
                material.smoothness = fastSqrt(min(0.8, sumOf(material.albedo.rgb)));
                material.emissive = cubed(maxOf(material.albedo.rgb));
                material.metallic = 0.17;
            }

            // Amethyst
            else if(id == 10084 || id == 10085){
                material.smoothness = sumOf(material.albedo.rgb) * 0.333;
                material.emissive = material.smoothness * material.smoothness * material.smoothness * material.smoothness * (id == 10085 ? material.smoothness * material.smoothness * material.smoothness * material.smoothness * material.smoothness * material.smoothness : material.smoothness);
                 material.metallic = 0.17;
            }

            // Netherack gem ores
            else if(id == 10081){
                if(material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                    material.smoothness = min(0.93, sumOf(material.albedo.rgb));
                    material.metallic = 0.17;
                }
            }

            // Metal ores
            else if(id == 10096 && (material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b)){
                float metalOreColSum = sumOf(material.albedo.rgb);
                if(metalOreColSum > 0.75){
                    material.smoothness = metalOreColSum * 0.333;
                    material.metallic = 1.0;
                }
            }

            // Netherack metal ores
            else if(id == 10097 && maxOf(material.albedo.rg) > 0.6){
                material.smoothness = sumOf(material.albedo.rgb) * 0.333;
                material.metallic = 1.0;
            }

            // Metal blocks
            else if(id == 10098){
                material.smoothness = sumOf(material.albedo.rgb) * 0.333;
                material.metallic = 1.0;
            }

            // Dark metals
            else if(id == 10099){
                material.smoothness = sumOf(material.albedo.rgb) * 0.1998 + 0.4;
                material.metallic = 1.0;
            }

            // Rails
            else if(id == 10100 && material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                material.smoothness = sumOf(material.albedo.rgb) * 0.333;
                material.metallic = 1.0;
            }

            // Polished blocks
            else if(id == 10112) material.smoothness = sumOf(material.albedo.rgb) * 0.1998 + 0.4;

            // Packed ice
            else if(id == 10065) material.smoothness = 0.96;
        #endif

        #ifdef WATER
            // Glass and ice
            if(id == 10064 || id == 10065) material.smoothness = 0.96;

            // Gelatin
            else if(id == 10066) material.smoothness = 0.96;
        #endif
    #endif

    #if COLOR_MODE == 0
        material.albedo.rgb *= vertexColor;
    #elif COLOR_MODE == 1
        material.albedo.rgb = vec3(1);
    #elif COLOR_MODE == 2
        material.albedo.rgb = vec3(0);
    #elif COLOR_MODE == 3
        material.albedo.rgb = vertexColor;
    #endif
}