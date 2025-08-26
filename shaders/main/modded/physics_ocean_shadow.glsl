/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out vec3 vertexColor;

        out vec2 texCoord;
        out vec2 waterNoiseUv;

        uniform vec3 cameraPosition;

        uniform mat4 shadowModelViewInverse;

        #if defined WATER_ANIMATION || defined WORLD_CURVATURE
            uniform mat4 shadowModelView;
        #endif

        // Physics mod varyings
        out float physics_localWaviness;

        out vec2 physics_localPosition;

        #include "/lib/modded/physicsMod/physicsModVertex.glsl"

        #ifdef WATER_ANIMATION
            uniform float vertexFrameTime;

            #include "/lib/vertex/waveWater.glsl"
        #endif

        void main(){
            // Get buffer texture coordinates
            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
            // Get vertex color
            vertexColor = gl_Color.rgb;

            // Get vertex view position
            vec3 vertexShdViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
            // Get vertex eye player position
            vec3 vertexShdEyePlayerPos = mat3(shadowModelViewInverse) * vertexShdViewPos;

            // Get vertex feet player position
            vec2 vertexShdFeetPlayerPosXZ = vertexShdEyePlayerPos.xz + shadowModelViewInverse[3].xz;
            // Get world position
            vec2 vertexShdWorldPosXZ = vertexShdFeetPlayerPosXZ + cameraPosition.xz;

            // Get water noise uv position
            waterNoiseUv = vertexShdWorldPosXZ * waterTileSizeInv;

            #ifdef WATER_ANIMATION
                vertexShdEyePlayerPos = getWaterWave(vertexShdEyePlayerPos, vertexShdWorldPosXZ, 11102, vertexFrameTime);
            #endif

            // Physics mod vertex displacement
            // basic texture to determine how shallow/far away from the shore the water is
            float physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

            // pass this to the fragment shader to fetch the texture there for per fragment normals
            vec2 physics_localPosition = (gl_Vertex.xz - physics_waveOffset) * PHYSICS_XZ_SCALE * physics_oceanWaveHorizontalScale;

            // transform gl_Vertex (since it is the raw mesh, i.e. not transformed yet)
            vertexShdEyePlayerPos.y += physics_waveHeight(physics_localPosition, physics_localWaviness);

            #ifdef WORLD_CURVATURE
                // Apply curvature distortion
                vertexShdEyePlayerPos.y -= dot(vertexShdFeetPlayerPosXZ, vertexShdFeetPlayerPosXZ) * worldCurvatureInv;
            #endif

            // Convert back to vertex view position
            vertexShdViewPos = mat3(shadowModelView) * vertexShdEyePlayerPos;

            // Convert to clip position and output as final position
            // gl_Position = gl_ProjectionMatrix * vertexShdViewPos;
            gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexShdViewPos;
            gl_Position.z += gl_ProjectionMatrix[3].z;

            gl_Position.w = 1.0;

            // Apply shadow distortion
            gl_Position.xyz = vec3(gl_Position.xy / (length(gl_Position.xy) + 0.1), gl_Position.z * 0.2);
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
        layout(location = 0) out vec3 shadowColOut; // shadowcolor0

        flat in vec3 vertexColor;

        in vec2 texCoord;
        in vec2 waterNoiseUv;

        uniform sampler2D gtexture;
        
        #if UNDERWATER_CAUSTICS != 0 && defined SHADOW_COLOR
            uniform float fragmentFrameTime;

            #if UNDERWATER_CAUSTICS == 1
                uniform int isEyeInWater;
            #endif

            #include "/lib/utility/noiseFunctions.glsl"
            #include "/lib/surface/water.glsl"
        #endif

        void main(){
            #ifdef SHADOW_COLOR
                vec4 shdAlbedo = textureLod(gtexture, texCoord, 0);

                // Alpha test, discard and return immediately
                if(shdAlbedo.a < ALPHA_THRESHOLD){ discard; return; }

                // If the object is fully opaque, set to black. This fixes "color leaking" filtered shadows
                if(shdAlbedo.a == 1){
                    shadowColOut = vec3(0);
                    return;
                }

                // If the object is not opaque, proceed with shadow coloring and caustics
                #ifdef WATER_FLAT
                    shadowColOut = vec3(0.8);

                    #if UNDERWATER_CAUSTICS == 2
                        shadowColOut = vec3(squared(0.256 + getCellNoise(waterNoiseUv)) * 0.8);
                    #elif UNDERWATER_CAUSTICS == 1
                        if(isEyeInWater == 1) shadowColOut = vec3(squared(0.256 + getCellNoise(waterNoiseUv)) * 0.8);
                    #endif
                #else
                    shadowColOut = shdAlbedo.rgb;

                    #if UNDERWATER_CAUSTICS == 2
                        shadowColOut *= squared(0.256 + getCellNoise(waterNoiseUv));
                    #elif UNDERWATER_CAUSTICS == 1
                        if(isEyeInWater == 1) shadowColOut *= squared(0.256 + getCellNoise(waterNoiseUv));
                    #endif
                #endif

                shadowColOut = toLinear(shadowColOut * vertexColor);
            #else
                // Alpha test, discard and return immediately
                if(textureLod(gtexture, texCoord, 0).a < ALPHA_THRESHOLD){ discard; return; }

                shadowColOut = vec3(0);
            #endif
        }
    #else
        void main(){
            discard; return;
        }
    #endif
#endif