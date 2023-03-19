/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: Temporal Anti-Aliasing (TAA)

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

    #if (defined PREVIOUS_FRAME && defined AUTO_EXPOSURE && (defined SSR || defined SSGI)) || ANTI_ALIASING >= 2
        uniform sampler2D colortex5;
    #endif

    #if ANTI_ALIASING >= 2
        uniform vec3 cameraPosition;
        uniform vec3 previousCameraPosition;

        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferPreviousModelView;

        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferPreviousProjection;

        uniform sampler2D depthtex0;

        #include "/lib/utility/convertPrevScreenSpace.glsl"

        #include "/lib/antialiasing/taa.glsl"
    #endif

    void main(){
        #if ANTI_ALIASING >= 2
            vec3 sceneCol = textureTAA(ivec2(gl_FragCoord.xy));
        #else
            vec3 sceneCol = texelFetch(gcolor, ivec2(gl_FragCoord.xy), 0).rgb;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor

        #if (defined PREVIOUS_FRAME && (defined SSR || defined SSGI)) || ANTI_ALIASING >= 2
        /* DRAWBUFFERS:05 */
            #ifdef AUTO_EXPOSURE
                gl_FragData[1] = vec4(sceneCol, texelFetch(colortex5, ivec2(0), 0).a); // colortex5
            #else
                gl_FragData[1] = vec4(sceneCol, 1); // colortex5
            #endif
        #endif
    }
#endif