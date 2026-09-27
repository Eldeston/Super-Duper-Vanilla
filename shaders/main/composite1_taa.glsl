/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: Temporal Anti-Aliasing (TAA)

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    noperspective out vec2 texCoord;

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    #if (defined PREVIOUS_FRAME && (defined SSR || defined SSGI)) || ANTI_ALIASING >= 2
        /* RENDERTARGETS: 4,5 */
        #ifdef AUTO_EXPOSURE
            out vec4 temporalDataOut; // colortex5
        #else
            out vec3 temporalDataOut; // colortex5
        #endif
    #endif

    noperspective in vec2 texCoord;

    uniform sampler2D colortex4;

    #if (defined PREVIOUS_FRAME && (defined SSR || defined SSGI)) || ANTI_ALIASING >= 2
        uniform sampler2D colortex5;
    #endif

    #if ANTI_ALIASING >= 2
        uniform vec3 cameraPosition;
        uniform vec3 camPosDelta;

        uniform mat4 gbufferModelViewInverse;
        uniform mat4 gbufferPreviousModelView;

        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferPreviousProjection;

        uniform sampler2D depthtex0;

        #include "/lib/utility/projectionFunctions.glsl"
        #include "/lib/utility/prevProjectionFunctions.glsl"

        #include "/lib/antialiasing/taa.glsl"
    #endif

    void main(){
        #if ANTI_ALIASING >= 2
            sceneColOut = textureTAA(ivec2(gl_FragCoord.xy));
        #else
            sceneColOut = texelFetch(colortex4, ivec2(gl_FragCoord.xy), 0).rgb;
        #endif

        #if ((defined SSR || defined SSGI) && defined PREVIOUS_FRAME) || ANTI_ALIASING >= 2
            #ifdef AUTO_EXPOSURE
                temporalDataOut = vec4(sceneColOut, texelFetch(colortex5, ivec2(0), 0).a);
            #else
                temporalDataOut = sceneColOut;
            #endif
        #endif
    }
#endif