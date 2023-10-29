/*
================================ /// Super Duper Vanilla v1.3.5 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.5 /// ================================
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

            // Get vertex view position
            vec3 vertexShadowViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
            // Get vertex feet player position
            vec3 vertexShadowFeetPlayerPos = mat3(shadowModelViewInverse) * vertexShadowViewPos + shadowModelViewInverse[3].xyz;

            // Get world position
            vec3 vertexShadowWorldPos = vertexShadowFeetPlayerPos + cameraPosition;

            // Get water noise uv position
            waterNoiseUv = vertexShadowWorldPos.xz / WATER_TILE_SIZE;

            #if defined TERRAIN_ANIMATION || defined WATER_ANIMATION || defined WORLD_CURVATURE || defined PHYSICS_OCEAN
                #if defined TERRAIN_ANIMATION || defined WATER_ANIMATION || defined PHYSICS_OCEAN
                    // Apply terrain wave animation
                    vertexShadowFeetPlayerPos.xyz = getShadowWave(vertexShadowFeetPlayerPos.xyz, vertexShadowWorldPos, at_midBlock.y * 0.015625, mc_Entity.x, saturate(gl_MultiTexCoord1.y * 0.00416667));
                #endif

                #ifdef WORLD_CURVATURE
                    // Apply curvature distortion
                    vertexShadowFeetPlayerPos.y -= dot(vertexShadowFeetPlayerPos.xz, vertexShadowFeetPlayerPos.xz) / WORLD_CURVATURE_SIZE;
                #endif

                // Convert back to vertex view position
                vertexShadowViewPos = mat3(shadowModelView) * vertexShadowFeetPlayerPos + shadowModelView[3].xyz;
            #endif

            // Convert to clip position and output as final position
            // gl_Position = gl_ProjectionMatrix * vertexShadowViewPos;
            gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexShadowViewPos;
            gl_Position.z += gl_ProjectionMatrix[3].z;

            gl_Position.w = 1.0;

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
        /* RENDERTARGETS: 0 */
        layout(location = 0) out vec3 shadowColOut; // gcolor

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
                    if(blockId == 11102){
                        #ifdef WATER_FLAT
                            #if UNDERWATER_CAUSTICS == 2
                                shadowColOut = vec3(squared(0.256 + getCellNoise(waterNoiseUv)) * 0.8);
                            #elif UNDERWATER_CAUSTICS == 1
                                shadowColOut = vec3(0.8);
                                if(isEyeInWater == 1) shadowColOut = vec3(squared(0.256 + getCellNoise(waterNoiseUv)) * 0.8);
                            #endif
                        #else
                            #if UNDERWATER_CAUSTICS == 2
                                shadowColOut = shdAlbedo.rgb * squared(0.256 + getCellNoise(waterNoiseUv));
                            #elif UNDERWATER_CAUSTICS == 1
                                shadowColOut = shdAlbedo.rgb;
                                if(isEyeInWater == 1) shadowColOut *= squared(0.256 + getCellNoise(waterNoiseUv));
                            #endif
                        #endif

                        shadowColOut = toLinear(shadowColOut * vertexColor);
                    }
                    // To give white colored glass some proper shadows except water
                    else shadowColOut = toLinear(shdAlbedo.rgb * vertexColor) * (1.0 - shdAlbedo.a * shdAlbedo.a);
                }
                // If the object is fully opaque, set to black. This fixes "color leaking" filtered shadows
                else shadowColOut = vec3(0);
            #else
                // Alpha test, discard immediately
                if(textureLod(tex, texCoord, 0).a < ALPHA_THRESHOLD) discard;

                shadowColOut = vec3(0);
            #endif
        }
    #else
        void main(){
            discard;
        }
    #endif
#endif