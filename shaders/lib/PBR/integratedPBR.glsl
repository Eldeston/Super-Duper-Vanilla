// Texture coordinate derivatives
vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);

// The Integrated PBR calculation
void getPBR(inout dataPBR material, in int id){
    // Assign albedo
    material.albedo = textureGrad(gtexture, texCoord, dcdx, dcdy);

    // Alpha test, discard and return immediately
    if(material.albedo.a < ALPHA_THRESHOLD) return;

    // Assign default normal map
    material.normal = TBN[2];

    // Generate bumped normals
    #if (defined TERRAIN || defined WATER || defined BLOCK || defined BLOCK_TRANSLUCENT) && defined NORMAL_GENERATION
        if(id != 11100 && id != 11102 && id != 12101){
            const float autoGenNormPixSize = 1.0 / NORMAL_GENERATION_RESOLUTION;
            vec2 topRightCorner = fract(vTexCoord - autoGenNormPixSize) * vTexCoordScale + vTexCoordPos;
            vec2 bottomLeftCorner = fract(vTexCoord + autoGenNormPixSize) * vTexCoordScale + vTexCoordPos;

            float d0 = sumOf(textureGrad(gtexture, topRightCorner, dcdx, dcdy).rgb);
            float d1 = sumOf(textureGrad(gtexture, vec2(bottomLeftCorner.x, topRightCorner.y), dcdx, dcdy).rgb);
            float d2 = sumOf(textureGrad(gtexture, vec2(topRightCorner.x, bottomLeftCorner.y), dcdx, dcdy).rgb);

            vec2 slopeNormal = d0 - vec2(d1, d2);
            // TBN * fastNormalize(vec3(slopeNormal, 1))
            float lengthInv = inversesqrt(lengthSquared(slopeNormal) + 1.0);
            material.normal = TBN * vec3(slopeNormal * lengthInv, lengthInv);

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

        // If lava and fire
        if(id == 11100 || id == 12101) material.emissive = 1.0;

        // Foliage and corals
        else if((id >= 10000 && id <= 10800) || (id >= 11600 && id <= 11799) || id == 10900 || id == 11101 || id == 12200) material.ss = 1.0;
    #else
        // For others, don't use vanilla AO
        material.ambient = 1.0;
    #endif

    #ifdef WATER
        // If water
        if(id == 11102){
            material.metallic = 0.02;
            material.smoothness = 0.96;

            #ifdef WATER_FLAT
                material.albedo.rgb = vec3(0.8);
            #endif
        }

        // Nether portal
        else if(id == 12100){
            material.emissive = sumOf(material.albedo.rgb) * 0.33333333;
            material.smoothness = 0.96;
        }
    #endif

    #if defined ENTITIES || defined ENTITIES_TRANSLUCENT
        // Basic whole entity emission
        if(id == 10130) material.emissive = cubed(sumOf(material.albedo.rgb) * 0.33333333);

        // End crystal
        else if(id == 10131) material.emissive = float(material.albedo.r > sumOf(material.albedo.gb) * 0.5);

        // Charged creeper
        else if(id == 10132) material.emissive = float(material.albedo.b > material.albedo.g);
    #endif

    #if PBR_MODE <= 2
        #if defined TERRAIN || defined BLOCK
            float albedoSum = sumOf(material.albedo.rgb);
            float albedoMax = maxOf(material.albedo.rgb);
            float albedoMin = minOf(material.albedo.rgb);

            // Glow berries
            if(id == 10001) material.emissive = sumOf(material.albedo.rg) > material.albedo.g * 2.0 ? smoothstep(0.3, 0.9, albedoMax) : material.emissive;

            // Fungus
            else if(id == 10002 || id == 10601 || id == 12102) material.emissive = float(sumOf(material.albedo.rg) > 1);

            // Torch flower
            else if(id == 10602 || id == 12103) material.emissive = squared(material.albedo.r * 0.5) * float(material.albedo.r > 0.6);

            /// -------------------------------- /// Emissive blocks /// -------------------------------- ///

            // Frog lights
            else if(id == 12300){
                material.emissive = cubed(max(0.0, albedoSum * 1.33333332 - 3.0));

                material.smoothness = 0.9;
            }

            // Reflective light emitting blocks and redstone lamps
            else if(id == 12301){
                material.emissive = saturate(albedoSum * 1.33333332 - 2.0);

                material.smoothness = 0.9;
            }

            // Creaking heart
            else if(id == 12302){
                material.emissive = saturate(squared((material.albedo.r + material.albedo.g) * 0.66666667) - material.albedo.b);
            }

            // Redstone block
            else if(id == 12303){
                material.emissive = material.albedo.r * 0.25;

                material.metallic = 1.0;
                material.smoothness = 0.9 * fastSqrt(material.albedo.r);
            }

            /// -------------------------------- /// Metallic blocks /// -------------------------------- ///

            // Dark metals
            else if(id == 12400){
                material.metallic = 1.0;
                material.smoothness = albedoSum * 0.1999 + 0.4;
            }

            // Metal blocks
            else if(id == 12401){
                material.metallic = 1.0;
                material.smoothness = albedoSum * 0.3 + 0.06;
            }

            // Copper blocks
            else if(id == 12402 || id == 12403){
                material.metallic = 1.0;
                material.smoothness = maxOf(material.albedo.rg) * 0.96;

                if(id == 12403){
                    // material.emissive = min(1.0, squared(max(0.0, squared(material.albedo.r * material.albedo.g) * (squared(material.albedo.b) * 0.5 + 0.5) - 0.1) * 2.0));
                    material.emissive = max(0.0, hermiteMix(0.45, 1.0, material.albedo.r * material.albedo.g));
                }
            }

            /// -------------------------------- /// Smooth blocks /// -------------------------------- ///

            // Crystal blocks
            else if(id == 12501){
                material.metallic = 0.17;
                material.smoothness = fastSqrt(min(0.8, albedoSum));
            }

            #if PBR_MODE == 2 && defined ROUGH_REFLECTIONS
                // Stone blocks
                else if(id == 12502) material.smoothness = albedoMin * 0.6;

                // Deepslate
                else if(id == 12503) material.smoothness = albedoMax * 0.75;

                // Granite
                else if(id == 12504) material.smoothness = albedoMax * 0.6;

                // Diorite
                else if(id == 12505) material.smoothness = albedoMin * 0.45;

                // Andesite
                else if(id == 12506) material.smoothness = albedoMin * 0.6;

                // Tuff
                else if(id == 12507) material.smoothness = albedoMax * 0.6;

                // Blackstone
                else if(id == 12508) material.smoothness = albedoMax * 0.75;

                // Basalt
                else if(id == 12509) material.smoothness = albedoMax * 0.6;

                // Quartz
                else if(id == 12510) material.smoothness = albedoMin * 0.75;

                // Purpur
                else if(id == 12511) material.smoothness = albedoMax * 0.9;

                // Calcite
                else if(id == 12512) material.smoothness = albedoMin * 0.45;

                // Prismarine
                else if(id == 12513) material.smoothness = albedoMax * 0.9;

                // Sulfur
                else if(id == 12514) material.smoothness = albedoMax * 0.6;

                // Cinnabar
                else if(id == 12515) material.smoothness = albedoMax * 0.6;
            #endif


            // Ice blocks
            else if(id == 12516){
                float materialIce = albedoMax * 0.96;
                material.ss = materialIce;

                material.smoothness = materialIce;
            }

            // Snow blocks
            else if(id == 12517){
                float materialIce = albedoSum * 0.33333333 * 0.45;
                material.ss = materialIce;

                #if PBR_MODE == 2 && defined ROUGH_REFLECTIONS
                    material.smoothness = materialIce;
                #endif
            }

            #if PBR_MODE == 2 && defined ROUGH_REFLECTIONS
                // Soil blocks
                else if(id == 12518) material.smoothness = fastSqrt(albedoMax) * 0.3;

                // Concrete & terracotta blocks
                else if(id == 12519) material.smoothness = fastSqrt(albedoSum * 0.33333333) * 0.15 + 0.3;
            #endif

            /// -------------------------------- /// Ores /// -------------------------------- ///

            // Crystals
            else if(id == 12600){
                if(material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b){
                    if(albedoSum > 0.75){
                        material.metallic = 0.17;
                        material.smoothness = min(0.96, albedoSum * 0.5);
                    }
                }
            }

            // Netherack crystals
            else if(id == 12601){
                if(material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                    material.metallic = 0.17;
                    material.smoothness = min(0.93, albedoSum * 0.5);
                }
            }

            // Metals
            else if(id == 12700){
                if(material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b){
                    if(albedoSum > 0.75){
                        material.metallic = 1.0;
                        material.smoothness = maxOf(material.albedo.rg) * 0.96;
                    }
                }
            }

            // Netherack metals
            else if(id == 12701){
                if(maxOf(material.albedo.rg) > 0.6){
                    material.metallic = 1.0;
                    material.smoothness = maxOf(material.albedo.rg) * 0.96;
                }
            }

            // Gilded
            else if(id == 12702){
                if(maxOf(material.albedo.rg) > material.albedo.b * 2.0){
                    material.metallic = 1.0;
                    material.smoothness = maxOf(material.albedo.rg) * 0.96;
                }
            }

            /// -------------------------------- /// Pyro emissives /// -------------------------------- ///

            else if(id == 12800) material.emissive = smoothen(max(0.0, albedoMax - 0.75) * 4.0);
            else if(id == 10801 || id == 12801) material.emissive = squared(squared(saturate(albedoSum * 0.83333333 - 1)));

            /// -------------------------------- /// Redstone emissives /// -------------------------------- ///

            // Redstone components
            else if(id == 12900){
                // Redstone stuff
                if(material.albedo.r > material.albedo.b * 2.4){
                    material.emissive = float(material.albedo.r > 0.5) * 0.5;

                    material.metallic = 1.0;
                    material.smoothness = 0.9;
                }
            }

            // Redstone wire
            else if(id == 12901){
                material.emissive = squared(vertexColor.r) * 0.25;

                material.metallic = 1.0;
                material.smoothness = vertexColor.r * 0.45;
            }

            // Rails
            else if(id == 12902){
                if(material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                    material.metallic = 1.0;
                    material.smoothness = albedoSum * 0.32;
                }
            }

            /// -------------------------------- /// Bioluminescent /// -------------------------------- ///

            // Glow lichen
            else if(id == 13000) material.emissive = material.albedo.r > material.albedo.b ? 1.0 : 0.0;

            // Stems
            else if(id == 13001) material.emissive = material.albedo.r < 0.1 ? albedoMax * 0.72 : material.emissive;
            else if(id == 13002) material.emissive = material.albedo.b < 0.16 && material.albedo.r > 0.4 ? albedoMax * 0.72 : material.emissive;

            // Chorus
            else if(id == 13003) material.emissive = float(sumOf(material.albedo.rg) > 1.1);
            else if(id == 13004) material.emissive = exp(sumOf(material.albedo.gb) * 8.0 - 16.0);

            // Common sculk
            else if(id == 13005){
                material.emissive = cubed(material.albedo.b);

                material.smoothness = 0.45;
            }

            // Uncommon sculk
            else if(id == 13006){
                material.emissive = cubed(material.albedo.b);

                material.smoothness = 0.45;
            }

            /// -------------------------------- /// Crystal /// -------------------------------- ///

            // Beacon
            else if(id == 13100) material.emissive = exp(albedoSum * 2.66666664 - 8.0);

            // End portal frame
            else if(id == 13101) material.emissive = sumOf(material.albedo.gb) > material.albedo.r * 2.0 ? squared(saturate((material.albedo.g - material.albedo.b) * 4.0)) : 0.0;

            // Crying obsidian
            else if(id == 13102){
                material.emissive = cubed(albedoMax);

                material.metallic = 0.17;
                material.smoothness = fastSqrt(min(0.8, albedoSum));
            }

            // Amethyst
            else if(id == 13103 || id == 13104){
                float amethystAverage = albedoSum * 0.33333333;
                float amethystLumaSquared = squared(amethystAverage);
                float amethystLumaSquaredSquared = squared(amethystLumaSquared);
                material.emissive = amethystLumaSquaredSquared * (id == 13103 ? amethystLumaSquared * amethystLumaSquaredSquared : amethystAverage);
                
                material.metallic = 0.17;
                material.smoothness = amethystAverage * 0.6 + 0.3;
            }
        #endif

        #if defined WATER || defined BLOCK
            // Glass, and jelly blocks
            if(id == 12500) material.smoothness = fastSqrt(maxOf(material.albedo.rgb)) * 0.96;

            // Transparent ice blocks
            else if(id == 12520){
                float materialIce = maxOf(material.albedo.rgb) * 0.96;
                material.ss = materialIce;

                material.smoothness = materialIce;
            }
        #endif

        #ifdef BLOCK
            // Raid den crystal (Modded)
            if(id == 12304){
                material.emissive = cubed(maxOf(material.albedo.rgb)) * 0.25;

                material.smoothness = 0.9;
            }
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