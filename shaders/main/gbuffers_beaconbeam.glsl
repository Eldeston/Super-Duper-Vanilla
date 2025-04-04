/*
================================ /// Super Duper Vanilla v1.3.7 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.7 /// ================================
*/

/// Buffer features: TAA jittering, direct shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec4 vertexColor;

    out vec2 texCoord;

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
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
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
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 sceneColOut; // gcolor

    flat in vec4 vertexColor;

    in vec2 texCoord;

    // Get albedo texture
    uniform sampler2D tex;

    void main(){
        vec4 albedo = textureLod(tex, texCoord, 0) * vertexColor;

        // Alpha test, discard and return immediately
        if(albedo.a < ALPHA_THRESHOLD){ discard; return; }

        #if COLOR_MODE == 1
            albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            albedo.rgb = vertexColor.rgb;
        #endif

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

        sceneColOut = vec4(albedo.rgb * EMISSIVE_INTENSITY, albedo.a);
    }
#endif