/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: Does nothing, for now

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING && defined WORLD_LIGHT
        noperspective out vec2 texCoord;
    #endif

    void main(){
        #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING && defined WORLD_LIGHT
            // Get buffer texture coordinates
            texCoord = gl_MultiTexCoord0.xy;
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 volColOut; // colortex0

    #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING && defined WORLD_LIGHT
        /* RENDERTARGETS: 0,6 */
        layout(location = 1) out vec3 tempColOut; // colortex6
        
        noperspective in vec2 texCoord;

        uniform int halfViewWidth;
        uniform int halfViewHeight;

        // uniform float frameTime;

        uniform vec3 camPosDelta;
        uniform vec3 cameraPosition;

        uniform mat4 gbufferProjectionInverse;
        uniform mat4 gbufferModelViewInverse;

        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;

        uniform sampler2D colortex0;
        uniform sampler2D colortex6;
        uniform sampler2D depthtex0;

        #include "/lib/utility/projectionFunctions.glsl"
        #include "/lib/utility/prevProjectionFunctions.glsl"

        // https://sugulee.wordpress.com/2021/06/21/temporal-anti-aliasingtaa-tutorial/
        vec3 volumetricAccumulation(in ivec2 screenTexelCoord){
            // Current color
            vec3 currColor = texelFetch(colortex0, screenTexelCoord, 0).rgb;

            // Previous coord
            vec2 prevTexCoord = getPrevScreenCoord(texCoord, getDepth(depthtex0, screenTexelCoord, 0));
            if(prevTexCoord.x < 0 || prevTexCoord.y < 0 || prevTexCoord.x > 1 || prevTexCoord.y > 1) return currColor;

            // Previous color
            vec3 prevColor = texelFetch(colortex6, ivec2(prevTexCoord.x * halfViewWidth, prevTexCoord.y * halfViewHeight), 0).rgb;

            // Apply clamping on the history color.
            vec3 nearCol0 = texelFetch(colortex0, ivec2(screenTexelCoord.x - 1, screenTexelCoord.y), 0).rgb;
            vec3 nearCol1 = texelFetch(colortex0, ivec2(screenTexelCoord.x, screenTexelCoord.y - 1), 0).rgb;
            vec3 nearCol2 = texelFetch(colortex0, ivec2(screenTexelCoord.x + 1, screenTexelCoord.y), 0).rgb;
            vec3 nearCol3 = texelFetch(colortex0, ivec2(screenTexelCoord.x, screenTexelCoord.y + 1), 0).rgb;
            
            vec3 boxMin = min(currColor, min(nearCol0, min(nearCol1, min(nearCol2, nearCol3)))); // - 1.0 / 255.0;
            vec3 boxMax = max(currColor, max(nearCol0, max(nearCol1, max(nearCol2, nearCol3)))); // + 1.0 / 255.0;

            // Required to add the "sum color" of the remaining VL
            prevColor = clamp(prevColor, boxMin, boxMax);

            // float frameTimeExposure = frameTime;
            // frameTimeExposure /= (1.0 + frameTimeExposure);

            // Return temporal color
            return currColor * 0.1 + prevColor * 0.9;
            // return mix(prevColor, currColor, frameTimeExposure);
        }
    #endif

    void main(){
        #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING && defined WORLD_LIGHT
            volColOut = volumetricAccumulation(ivec2(gl_FragCoord.xy));
            tempColOut = volColOut;
        #else
            volColOut = vec3(0);
        #endif
    }
#endif