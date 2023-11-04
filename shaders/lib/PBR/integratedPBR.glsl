// Texture coordinate derivatives
vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);

// The Integrated PBR calculation
void getPBR(inout dataPBR material, in int id){
    // Assign albedo
    material.albedo = textureGrad(tex, texCoord, dcdx, dcdy);

    // Alpha test, discard and return immediately
    if(material.albedo.a < ALPHA_THRESHOLD){ discard; return; }

    // Assign default normal map
    material.normal = TBN[2];

    // Generate bumped normals
    #if (defined TERRAIN || defined WATER || defined BLOCK) && defined NORMAL_GENERATION
        if(id != 11100 && id != 11102 && id != 12001 && id != 12101){
            const float autoGenNormPixSize = 1.0 / NORMAL_GENERATION_RESOLUTION;
            vec2 topRightCorner = fract(vTexCoord - autoGenNormPixSize) * vTexCoordScale + vTexCoordPos;
            vec2 bottomLeftCorner = fract(vTexCoord + autoGenNormPixSize) * vTexCoordScale + vTexCoordPos;

            float d0 = sumOf(textureGrad(tex, topRightCorner, dcdx, dcdy).rgb);
            float d1 = sumOf(textureGrad(tex, vec2(bottomLeftCorner.x, topRightCorner.y), dcdx, dcdy).rgb);
            float d2 = sumOf(textureGrad(tex, vec2(topRightCorner.x, bottomLeftCorner.y), dcdx, dcdy).rgb);

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
    #else
        // For others, don't use vanilla AO
        material.ambient = 1.0;
    #endif

    #ifdef TERRAIN
        // If lava and fire
        if(id == 11100 || id == 12101) material.emissive = 1.0;

        // Foliage and corals
        else if((id >= 10000 && id <= 10800) || id == 10900 || id == 11101 || id == 12200) material.ss = 1.0;
    #endif

    #ifdef WATER
        // If water
        if(id == 11102){
            material.smoothness = 0.96;
            material.metallic = 0.02;

            #ifdef WATER_FLAT
                material.albedo.rgb = vec3(0.8);
            #endif
        }

        // Nether portal
        else if(id == 12100){
            material.smoothness = 0.96;
            material.emissive = maxOf(material.albedo.rgb);
        }
    #endif

    #if defined ENTITIES || defined ENTITIES_GLOWING
        // Basic whole entity emission
        if(id == 10130) material.emissive = cubed(sumOf(material.albedo.rgb) * 0.33333333);

        // End crystal
        else if(id == 10131) material.emissive = float(material.albedo.r > sumOf(material.albedo.gb) * 0.5);

        // Charged creeper
        else if(id == 10132) material.emissive = float(material.albedo.b > material.albedo.g);
    #endif

    #if PBR_MODE == 1
        #ifdef TERRAIN
            // Glow berries
            if(id == 10001) material.emissive = sumOf(material.albedo.rg) > material.albedo.g * 2.0 ? smoothstep(0.3, 0.9, maxOf(material.albedo.rgb)) : material.emissive;

            // Fungus
            else if(id == 10002 || id == 10601) material.emissive = float(sumOf(material.albedo.rg) > 1);

            // Torch flower
            else if(id == 10602) material.emissive = squared(material.albedo.r * 0.5);

            /// -------------------------------- /// Emissive blocks /// -------------------------------- ///

            // Frog lights
            else if(id == 12300){
                material.emissive = cubed(max(0.0, sumOf(material.albedo.rgb) * 1.33333332 - 3.0));
                material.smoothness = 0.9;
            }

            // Reflective light emitting blocks and redstone lamps
            else if(id == 12301){
                material.emissive = saturate(sumOf(material.albedo.rgb) * 1.33333332 - 2.0);
                material.smoothness = 0.9;
            }

            // Redstone block
            else if(id == 12302){
                material.emissive = 0.45;
                material.smoothness = 0.93 * material.albedo.r;
                material.metallic = 1.0;
            }

            /// -------------------------------- /// Metallic blocks /// -------------------------------- ///

            // Dark metals
            else if(id == 12400){
                material.smoothness = sumOf(material.albedo.rgb) * 0.1998 + 0.4;
                material.metallic = 1.0;
            }

            // Metal blocks
            else if(id == 12401){
                material.smoothness = sumOf(material.albedo.rgb) * 0.32;
                material.metallic = 1.0;
            }

            /// -------------------------------- /// Smooth blocks /// -------------------------------- ///

            // Packed ice and blue ice
            else if(id == 12501) material.smoothness = 0.96;

            // Crystal blocks
            else if(id == 12502){
                material.smoothness = fastSqrt(min(0.8, sumOf(material.albedo.rgb)));
                material.metallic = 0.17;
            }

            // Polished blocks
            else if(id == 12503) material.smoothness = sumOf(material.albedo.rgb) * 0.1998 + 0.4;

            /// -------------------------------- /// Ores /// -------------------------------- ///

            // Crystals
            else if(id == 12600){
                if(material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b){
                    float gemOreColSum = sumOf(material.albedo.rgb);
                    if(gemOreColSum > 0.75){
                        material.smoothness = min(0.96, gemOreColSum);
                        material.metallic = 0.17;
                    }
                }
            }

            // Netherack crystals
            else if(id == 12601){
                if(material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                    material.smoothness = min(0.93, sumOf(material.albedo.rgb));
                    material.metallic = 0.17;
                }
            }

            // Metals
            else if(id == 12700){
                if(material.albedo.r > material.albedo.g || material.albedo.r != material.albedo.b || material.albedo.g > material.albedo.b){
                    float metalOreColSum = sumOf(material.albedo.rgb);
                    if(metalOreColSum > 0.75){
                        material.smoothness = metalOreColSum * 0.32;
                        material.metallic = 1.0;
                    }
                }
            }

            // Netherack metals
            else if(id == 12701){
                if(maxOf(material.albedo.rg) > 0.6){
                    material.smoothness = sumOf(material.albedo.rgb) * 0.31;
                    material.metallic = 1.0;
                }
            }

            /// -------------------------------- /// Pyro emissives /// -------------------------------- ///

            else if(id == 12800) material.emissive = smoothen(max(0.0, maxOf(material.albedo.rgb) - 0.75) * 4.0);
            else if(id == 10801 || id == 12801) material.emissive = squared(squared(saturate(sumOf(material.albedo.rgb) * 0.83333333 - 1)));

            /// -------------------------------- /// Redstone emissives /// -------------------------------- ///

            else if(id == 12900 || id == 12901){
                // Redstone stuff
                if(material.albedo.r > material.albedo.b * 2.4){
                    material.emissive = float(material.albedo.r > 0.5);
                    material.smoothness = 0.93;
                    material.metallic = 1.0;
                }

                // Rails
                if(id == 12901){
                    if(material.albedo.r < material.albedo.g * 1.6 && material.albedo.r < material.albedo.b * 1.6){
                        material.smoothness = sumOf(material.albedo.rgb) * 0.32;
                        material.metallic = 1.0;
                    }
                }
            }

            /// -------------------------------- /// Bioluminescent /// -------------------------------- ///

            // Glow lichen
            else if(id == 13000) material.emissive = material.albedo.r > material.albedo.b ? 1.0 : 0.0;

            // Stems
            else if(id == 13001) material.emissive = material.albedo.r < 0.1 ? maxOf(material.albedo.rgb) * 0.72 : material.emissive;
            else if(id == 13002) material.emissive = material.albedo.b < 0.16 && material.albedo.r > 0.4 ? maxOf(material.albedo.rgb) * 0.72 : material.emissive;

            // Chorus
            else if(id == 13003) material.emissive = float(sumOf(material.albedo.rg) > 1.1);
            else if(id == 13004) material.emissive = exp(sumOf(material.albedo.gb) * 8.0 - 16.0);

            // Sculk
            else if(id == 13005){
                material.emissive = cubed(material.albedo.b);
                material.smoothness = 0.5;
            }

            /// -------------------------------- /// Crystal /// -------------------------------- ///

            // Beacon
            else if(id == 13100) material.emissive = exp(sumOf(material.albedo.rgb) * 2.66666664 - 8.0);

            // End portal frame
            else if(id == 13101) material.emissive = sumOf(material.albedo.gb) > material.albedo.r * 2.0 ? squared(saturate((material.albedo.g - material.albedo.b) * 4.0)) : 0.0;

            // Crying obsidian
            else if(id == 13102){
                material.smoothness = fastSqrt(min(0.8, sumOf(material.albedo.rgb)));
                material.emissive = cubed(maxOf(material.albedo.rgb));
                material.metallic = 0.17;
            }

            // Amethyst
            else if(id == 13103 || id == 13104){
                float amethystAverage = sumOf(material.albedo.rgb) * 0.33333333;
                material.smoothness = amethystAverage * 0.6 + 0.3;
                float amethystLumaSquared = squared(amethystAverage);
                float amethystLumaSquaredSquared = squared(amethystLumaSquared);
                material.emissive = amethystLumaSquaredSquared * (id == 13103 ? amethystLumaSquared * amethystLumaSquaredSquared : amethystAverage);
                material.metallic = 0.17;
            }
        #endif

        #ifdef WATER
            // Glass, ice, and jelly
            if(id == 12500) material.smoothness = 0.96;
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