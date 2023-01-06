/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender Studios.

    Copyright (C) 2020 Eldeston


    By downloading this you have agreed to the license and terms of use.
    These can be found inside the included license-file.

    Violating these terms may be penalized with actions according to the Digital Millennium Copyright Act (DMCA),
    the Information Society Directive and/or similar laws depending on your country.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: TAA jittering, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
    #endif

    #if ANTI_ALIASING == 2
        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
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

        vec2 lineScreenDirection = fastNormalize((ndc2.xy - ndc1.xy) * vec2(viewWidth, viewHeight));
        vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * (2.0 / vec2(viewWidth, viewHeight));

        if(lineOffset.x < 0.0) lineOffset *= -1.0;

        if(gl_VertexID % 2 == 0) gl_Position = vec4(vec3(ndc1.xy + lineOffset, ndc1.z) * linePosStart.w, linePosStart.w);
        else gl_Position = vec4(vec3(ndc1.xy - lineOffset, ndc1.z) * linePosStart.w, linePosStart.w);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    void main(){
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(0, 0, 0, 1); // gcolor
    }
#endif