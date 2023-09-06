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
    flat out float vertexAlpha;

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
        // Get vertex alpha
        vertexAlpha = gl_Color.a;
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        
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
    flat in float vertexAlpha;

    in vec2 texCoord;

    // Get albedo texture
    uniform sampler2D tex;

    void main(){
        // Get albedo color
        vec4 albedo = textureLod(tex, texCoord, 0);

        // Alpha test, discard immediately
        if(albedo.a < ALPHA_THRESHOLD) discard;

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

        // Glint emissive intensity
        const float emissive = EMISSIVE_INTENSITY * 0.25;

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(albedo.rgb * (vertexAlpha * emissive), albedo.a); // gcolor
    }
#endif