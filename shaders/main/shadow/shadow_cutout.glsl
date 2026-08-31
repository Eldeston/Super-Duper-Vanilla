/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #if defined WORLD_LIGHT && defined SHADOW_MAPPING
        out vec2 texCoord;

        attribute vec3 mc_Entity;

        #if defined TERRAIN_ANIMATION || defined WORLD_CURVATURE
            uniform mat4 shadowModelView;
            uniform mat4 shadowModelViewInverse;
        #endif

        #ifdef TERRAIN_ANIMATION
            uniform float vertexFrameTime;

            uniform vec3 cameraPosition;

            attribute vec3 at_midBlock;

            #include "/lib/vertex/waveTerrain.glsl"
        #endif

        #include "/lib/lighting/shdDistort.glsl"

        void main(){
            // Get buffer texture coordinates
            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

            // Get vertex view position
            vec3 vertexShdViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

            #if defined TERRAIN_ANIMATION || defined WORLD_CURVATURE
                // Get vertex eye player position
                vec3 vertexShdEyePlayerPos = mat3(shadowModelViewInverse) * vertexShdViewPos;

                // Get vertex feet player position
                vec2 vertexShdFeetPlayerPosXZ = vertexShdEyePlayerPos.xz + shadowModelViewInverse[3].xz;
            #endif

            #ifdef TERRAIN_ANIMATION
                // Apply terrain wave animation
                vertexShdEyePlayerPos = getTerrainWave(vertexShdEyePlayerPos, vertexShdFeetPlayerPosXZ + cameraPosition.xz, at_midBlock.y * 0.015625, mc_Entity.x, lightMapCoord(gl_MultiTexCoord1.y), vertexFrameTime);
            #endif
    
            #ifdef WORLD_CURVATURE
                // Apply curvature distortion
                vertexShdEyePlayerPos.y -= dot(vertexShdFeetPlayerPosXZ, vertexShdFeetPlayerPosXZ) * worldCurvatureInv;
            #endif

            #if defined TERRAIN_ANIMATION || defined WORLD_CURVATURE
                // Convert back to vertex view position
                vertexShdViewPos = mat3(shadowModelView) * vertexShdEyePlayerPos;
            #endif

            // Convert to clip position and output as final position
            // gl_Position = gl_ProjectionMatrix * vertexShdViewPos;
            gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexShdViewPos;
            gl_Position.z += gl_ProjectionMatrix[3].z;

            gl_Position.w = 1.0;

            // Apply shadow distortion
            gl_Position.xyz = getShdClipDistort(gl_Position.xyz);
        }
    #else
        void main(){
            gl_Position = vec4(-10);
        }
    #endif
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    #if defined WORLD_LIGHT && defined SHADOW_MAPPING
        /* RENDERTARGETS: 0 */
        layout(location = 0) out vec3 shadowColOut; // shadowcolor0

        in vec2 texCoord;

        uniform sampler2D gtexture;

        void main(){
            // Alpha test, discard and return immediately
            if(textureLod(gtexture, texCoord, 0).a < ALPHA_THRESHOLD){ discard; return; }

            shadowColOut = vec3(0);
        }
    #else
        void main(){
            discard; return;
        }
    #endif
#endif