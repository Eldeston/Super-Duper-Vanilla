/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: TAA jittering, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec3 vertexColor;

    uniform float pixelWidth;
    uniform float pixelHeight;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod8;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        // Get vertex color
        vertexColor = gl_Color.rgb;

        #ifdef WORLD_CURVATURE
            // Feet player pos
            vec4 linePosStart = gbufferModelViewInverse * (gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1));
            vec4 linePosEnd = gbufferModelViewInverse * (gl_ModelViewMatrix * vec4(gl_Vertex.xyz + gl_Normal.xyz, 1));

            linePosStart.y -= lengthSquared(linePosStart.xz) / WORLD_CURVATURE_SIZE;
            linePosEnd.y -= lengthSquared(linePosEnd.xz) / WORLD_CURVATURE_SIZE;
            
            linePosStart = gbufferModelView * linePosStart;
            linePosEnd = gbufferModelView * linePosEnd;
        #else
            // Feet player pos
            vec4 linePosStart = gl_ModelViewMatrix * vec4(gl_Vertex.xyz, 1);
            vec4 linePosEnd = gl_ModelViewMatrix * vec4(gl_Vertex.xyz + gl_Normal.xyz, 1);
        #endif

        // 1.0 - (1.0 / 256.0) = 0.99609375
        linePosStart = gl_ProjectionMatrix * vec4(linePosStart.xyz * 0.99609375, linePosStart.w);
        linePosEnd = gl_ProjectionMatrix * vec4(linePosEnd.xyz * 0.99609375, linePosEnd.w);

        vec3 ndc1 = linePosStart.xyz / linePosStart.w;
        vec3 ndc2 = linePosEnd.xyz / linePosEnd.w;

        vec2 lineScreenDirection = fastNormalize(ndc2.xy - ndc1.xy);
        vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * vec2(pixelWidth, pixelHeight) * 2.0;

        if(lineOffset.x < 0) lineOffset = -lineOffset;

        if(gl_VertexID % 2 == 0) gl_Position = vec4(vec3(ndc1.xy + lineOffset, ndc1.z) * linePosStart.w, linePosStart.w);
        else gl_Position = vec4(vec3(ndc1.xy - lineOffset, ndc1.z) * linePosStart.w, linePosStart.w);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in vec3 vertexColor;

    void main(){
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(vertexColor, 1); // gcolor
    }
#endif