/*
================================ /// Super Duper Vanilla v1.3.7 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.7 /// ================================
*/

/// Buffer features: Water caustics, direct shading, animation, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        uniform vec3 cameraPosition;

        uniform mat4 shadowModelView;
        uniform mat4 shadowModelViewInverse;

        void main(){
            // Get vertex view position
            vec3 vertexShdViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
            // Get vertex eye player position
            vec3 vertexShdEyePlayerPos = mat3(shadowModelViewInverse) * vertexShdViewPos;

            // Get vertex feet player position
            vec2 vertexShdFeetPlayerPosXZ = vertexShdEyePlayerPos.xz + shadowModelViewInverse[3].xz;

            #ifdef WORLD_CURVATURE
                // Apply curvature distortion
                vertexShdEyePlayerPos.y -= dot(vertexShdFeetPlayerPosXZ, vertexShdFeetPlayerPosXZ) * worldCurvatureInv;

                // Convert back to vertex view position
                vertexShdViewPos = mat3(shadowModelView) * vertexShdEyePlayerPos;
            #endif

            // Simple bias offset, uses a large bias to account for distorted geometry using distorted shadow mapping and maximum LOD size
            vertexShdViewPos.z -= (gl_NormalMatrix * fastNormalize(gl_Normal)).z * 4.0;

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
        layout(location = 0) out vec3 shadowColOut; // gcolor

        void main(){
            shadowColOut = vec3(0);
        }
    #else
        void main(){
            discard; return;
        }
    #endif
#endif