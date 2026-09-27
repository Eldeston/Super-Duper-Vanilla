/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: Motion blur

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef MOTION_BLUR
        noperspective out vec2 texCoord;
    #endif

    void main(){
        #ifdef MOTION_BLUR
            // Get buffer texture coordinates
            texCoord = gl_MultiTexCoord0.xy;
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    uniform sampler2D colortex4;

    #ifdef MOTION_BLUR
        noperspective in vec2 texCoord;

        uniform vec3 cameraPosition;
        uniform vec3 camPosDelta;

        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferPreviousModelView;

        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferPreviousProjection;

        uniform sampler2D depthtex0;

        #include "/lib/utility/projectionFunctions.glsl"
        #include "/lib/utility/prevProjectionFunctions.glsl"

        #include "/lib/utility/noiseFunctions.glsl"

        #include "/lib/post/motionBlur.glsl"
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Get scene color
        sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #ifdef MOTION_BLUR
            // Declare and get positions
            float depth = texelFetch(depthtex0, screenTexelCoord, 0).x;

            // Return immediately if player hand
            if(depth <= 0.56) return;

            // Apply motion blur
            sceneColOut = motionBlur(sceneColOut, depth, texelFetch(noisetex, screenTexelCoord & 255, 0).x);
        #endif
    }
#endif