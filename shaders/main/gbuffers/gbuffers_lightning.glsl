/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, PBR, lightning, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec4 vertexColor;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        // Get vertex color
        vertexColor = gl_Color;
        
	    // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

	    #ifdef WORLD_CURVATURE
            // Get vertex eye player position
            vec3 vertexEyePlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos;
            
            // Get vertex feet player position
            vec2 vertexFeetPlayerPosXZ = vertexEyePlayerPos.xz + gbufferModelViewInverse[3].xz;

            // Apply curvature distortion
            vertexEyePlayerPos.y -= lengthSquared(vertexFeetPlayerPosXZ) * worldCurvatureInv;
            
            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexEyePlayerPos;
        #endif

        // Convert to clip position and output as final position
        // gl_Position = gl_ProjectionMatrix * vertexViewPos;
        gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexViewPos;
        gl_Position.z += gl_ProjectionMatrix[3].z;

        gl_Position.w = -vertexViewPos.z;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    in vec4 vertexColor;

    uniform int entityId;

    void main(){
        #ifdef EPILEPSY_SAFETY
            vec3 boltTint = toLinear(LIGHTNING_COLOR) * 0.75;
            if(entityId == 10129) sceneColOut = vertexColor.rgb * boltTint;
            else sceneColOut = toLinear(vertexColor.rgb * vertexColor.a) * boltTint;
        #else
            vec3 boltTint = toLinear(LIGHTNING_COLOR) * EMISSIVE_INTENSITY;
            if(entityId == 10129) sceneColOut = vertexColor.rgb * boltTint * 1.5;
            else sceneColOut = toLinear(vertexColor.rgb * vertexColor.a) * boltTint * 1.5;
        #endif
    }
#endif