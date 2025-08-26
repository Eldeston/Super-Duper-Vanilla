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
        flat out int blockId;

        flat out vec3 vertexColor;

        out vec2 texCoord;

        #ifdef WORLD_CURVATURE
            uniform mat4 shadowModelView;
            uniform mat4 shadowModelViewInverse;
        #endif

        attribute vec3 mc_Entity;

        void main(){
            // Get block id
            blockId = int(mc_Entity.x);
            // Get buffer texture coordinates
            texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
            // Get vertex color
            vertexColor = gl_Color.rgb;

            // Get vertex view position
            vec3 vertexShdViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

            #ifdef WORLD_CURVATURE
                // Get vertex eye player position
                vec3 vertexShdEyePlayerPos = mat3(shadowModelViewInverse) * vertexShdViewPos;

                // Get vertex feet player position
                vec2 vertexShdFeetPlayerPosXZ = vertexShdEyePlayerPos.xz + shadowModelViewInverse[3].xz;

                // Apply curvature distortion
                vertexShdEyePlayerPos.y -= dot(vertexShdFeetPlayerPosXZ, vertexShdFeetPlayerPosXZ) * worldCurvatureInv;
                
                // Convert back to vertex view position
                vertexShdViewPos = mat3(shadowModelView) * vertexShdEyePlayerPos;
            #endif

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

        flat in int blockId;

        flat in vec3 vertexColor;

        in vec2 texCoord;

        uniform sampler2D gtexture;

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

                // To give white colored glass some proper shadows except water
                if(blockId != 11102){
                    shadowColOut = shdAlbedo.rgb;
                    return;
                }

                shadowColOut = toLinear(shdAlbedo.rgb * vertexColor);
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