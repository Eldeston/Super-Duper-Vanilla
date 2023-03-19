/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: Motion blur

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;
        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    in vec2 texCoord;

    uniform sampler2D gcolor;

    #ifdef MOTION_BLUR
        uniform vec3 cameraPosition;
        uniform vec3 previousCameraPosition;

        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferPreviousModelView;

        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferPreviousProjection;

        uniform sampler2D depthtex0;

        #include "/lib/utility/convertPrevScreenSpace.glsl"

        #include "/lib/utility/noiseFunctions.glsl"

        #include "/lib/post/motionBlur.glsl"
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        #ifdef MOTION_BLUR
            // Declare and get positions
            float depth = texelFetch(depthtex0, screenTexelCoord, 0).x;

            // Apply motion blur if not player hand
            if(depth > 0.56) sceneCol = motionBlur(sceneCol, depth, texelFetch(noisetex, screenTexelCoord & 255, 0).x);
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif