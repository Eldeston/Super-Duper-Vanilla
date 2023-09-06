/*
================================ /// Super Duper Vanilla v1.3.5 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.5 /// ================================
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
        uniform int frameMod8;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color;
        
	    #ifdef WORLD_CURVATURE
            // Get vertex feet player position
            vec4 vertexFeetPlayerPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

            // Apply curvature distortion
            vertexFeetPlayerPos.y -= lengthSquared(vertexFeetPlayerPos.xz) / WORLD_CURVATURE_SIZE;
            
            // Convert to clip position and output as final position
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexFeetPlayerPos);
        #else
            gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in vec4 vertexColor;

    in vec2 texCoord;

    // Get albedo texture
    uniform sampler2D tex;

    void main(){
        vec4 albedo = textureLod(tex, texCoord, 0) * vertexColor;

        // Alpha test, discard immediately
        if(albedo.a < ALPHA_THRESHOLD) discard;

        #if COLOR_MODE == 1
            albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            albedo.rgb = vertexColor.rgb;
        #endif

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(albedo.rgb * EMISSIVE_INTENSITY, albedo.a); // gcolor
    }
#endif