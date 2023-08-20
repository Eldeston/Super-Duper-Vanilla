/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: Water caustics, direct shading, animation, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out int blockId;

        flat out vec3 vertexColor;

        out vec2 texCoord;
        out vec2 waterNoiseUv;

        #ifdef PHYSICS_OCEAN
            // Physics mod compatibility
            #include "/lib/physicsMod/physicsModVertex.glsl"
        #endif

        uniform vec3 cameraPosition;

        uniform mat4 shadowModelView;
        uniform mat4 shadowModelViewInverse;

        #if defined TERRAIN_ANIMATION || defined WATER_ANIMATION
            #if TIMELAPSE_MODE == 2
                uniform float animationFrameTime;

                float newFrameTimeCounter = animationFrameTime;
            #else
                uniform float frameTimeCounter;

                float newFrameTimeCounter = frameTimeCounter;
            #endif

            attribute vec3 at_midBlock;

            #include "/lib/vertex/shadowWave.glsl"
        #endif

        attribute vec3 mc_Entity;

        #include "/lib/lighting/shdDistort.glsl"

        void main(){
            // Get block id
            blockId = int(mc_Entity.x);
            // Get buffer texture coordinates
            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
            // Get vertex color
            vertexColor = gl_Color.rgb;

            // Get vertex position (feet player pos)
            vec4 vertexPos = shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
            // Get world position
            vec3 worldPos = vertexPos.xyz + cameraPosition;
            // Get water noise uv position
            waterNoiseUv = worldPos.xz / WATER_TILE_SIZE;
            
            #if defined TERRAIN_ANIMATION || defined WATER_ANIMATION || defined WORLD_CURVATURE || defined PHYSICS_OCEAN
                #if defined TERRAIN_ANIMATION || defined WATER_ANIMATION || defined PHYSICS_OCEAN
                    // Apply terrain wave animation
                    vertexPos.xyz = getShadowWave(vertexPos.xyz, worldPos, at_midBlock.y * 0.015625, mc_Entity.x, saturate(gl_MultiTexCoord1.y * 0.00416667));
                #endif

                #ifdef WORLD_CURVATURE
                    // Apply curvature distortion
                    vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
                #endif

                // Convert to clip pos and output as position
                gl_Position = gl_ProjectionMatrix * (shadowModelView * vertexPos);
            #else
                gl_Position = ftransform();
            #endif

            // Apply shadow distortion
            gl_Position.xyz = distort(gl_Position.xyz);
        }
    #else
        void main(){
            gl_Position = vec4(-10);
        }
    #endif
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    #ifdef WORLD_LIGHT
        flat in int blockId;

        flat in vec3 vertexColor;

        in vec2 texCoord;
        in vec2 waterNoiseUv;

        uniform sampler2D tex;
        
        #if UNDERWATER_CAUSTICS != 0 && defined SHADOW_COLOR
            #if UNDERWATER_CAUSTICS == 1
                uniform int isEyeInWater;
            #endif

            #if TIMELAPSE_MODE != 0
                uniform float animationFrameTime;

                float newFrameTimeCounter = animationFrameTime;
            #else
                uniform float frameTimeCounter;

                float newFrameTimeCounter = frameTimeCounter;
            #endif

            #include "/lib/utility/noiseFunctions.glsl"
            #include "/lib/surface/water.glsl"
        #endif

        void main(){
            #ifdef SHADOW_COLOR
                vec4 shdAlbedo = textureLod(tex, texCoord, 0);

                // Alpha test, discard immediately
                if(shdAlbedo.a < ALPHA_THRESHOLD) discard;

                // If the object is not opaque, proceed with shadow coloring and caustics
                if(shdAlbedo.a != 1){
                    if(blockId == 15502){
                        #ifdef WATER_FLAT
                            #if UNDERWATER_CAUSTICS == 2
                                shdAlbedo.rgb = vec3(squared(0.256 + getCellNoise(waterNoiseUv)) * 0.8);
                            #elif UNDERWATER_CAUSTICS == 1
                                shdAlbedo.rgb = vec3(0.8);
                                if(isEyeInWater == 1) shdAlbedo.rgb *= squared(0.256 + getCellNoise(waterNoiseUv));
                            #endif
                        #else
                            #if UNDERWATER_CAUSTICS == 2
                                shdAlbedo.rgb *= squared(0.256 + getCellNoise(waterNoiseUv));
                            #elif UNDERWATER_CAUSTICS == 1
                                if(isEyeInWater == 1) shdAlbedo.rgb *= squared(0.256 + getCellNoise(waterNoiseUv));
                            #endif
                        #endif

                        shdAlbedo.rgb = toLinear(shdAlbedo.rgb * vertexColor);
                    }
                    // To give white colored glass some proper shadows except water
                    else shdAlbedo.rgb = toLinear(shdAlbedo.rgb * vertexColor) * (1.0 - shdAlbedo.a * shdAlbedo.a);
                }
                // If the object is fully opaque, set to black. This fixes "color leaking" filtered shadows
                else shdAlbedo.rgb = vec3(0);

            /* DRAWBUFFERS:0 */
                gl_FragData[0] = shdAlbedo;
            #else
                // Alpha test, discard immediately
                if(textureLod(tex, texCoord, 0).a < ALPHA_THRESHOLD) discard;

            /* DRAWBUFFERS:0 */
                gl_FragData[0] = vec4(0, 0, 0, 1);
            #endif
        }
    #else
        void main(){
            discard;
        }
    #endif
#endif