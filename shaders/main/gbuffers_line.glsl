/*
================================ /// Super Duper Vanilla v1.3.5 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.5 /// ================================
*/

/// Buffer features: TAA jittering, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec3 vertexColor;

    uniform float pixelWidth;
    uniform float pixelHeight;

    // 1.17 uniforms
    uniform mat4 modelViewMatrix;
    uniform mat4 projectionMatrix;

    #if ANTI_ALIASING == 2
        uniform int frameMod8;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    // Attributes (uses "in" instead of "attribute" because Mojank)
    in vec3 vaNormal;
    in vec3 vaPosition;

    in vec4 vaColor;

    void main(){
        // Get vertex color
        vertexColor = vaColor.rgb;

        // Feet player pos
        vec4 linePosStart = vec4(vaPosition, 1);
        vec4 linePosEnd = vec4(vaPosition + gl_Normal.xyz, 1);

        #ifdef WORLD_CURVATURE
            linePosStart.y -= lengthSquared(linePosStart.xz) / WORLD_CURVATURE_SIZE;
            linePosEnd.y -= lengthSquared(linePosEnd.xz) / WORLD_CURVATURE_SIZE;
        #endif

        // 1.0 - (1.0 / 256.0) = 0.99609375
        linePosStart = projectionMatrix * (modelViewMatrix * vec4(linePosStart.xyz * 0.99609375, linePosStart.w));
        linePosEnd = projectionMatrix * (modelViewMatrix * vec4(linePosEnd.xyz * 0.99609375, linePosEnd.w));

        vec3 ndc1 = linePosStart.xyz / linePosStart.w;
        vec3 ndc2 = linePosEnd.xyz / linePosEnd.w;

        vec2 lineScreenDirection = fastNormalize(ndc2.xy - ndc1.xy);
        vec2 lineOffset = vec2(-lineScreenDirection.y, lineScreenDirection.x) * vec2(pixelWidth, pixelHeight) * 2.0;

        if(lineOffset.x < 0) lineOffset = -lineOffset;
        if(gl_VertexID % 2 != 0) lineOffset = -lineOffset;

        gl_Position = vec4(vec3(ndc1.xy + lineOffset, ndc1.z) * linePosStart.w, linePosStart.w);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec3 sceneColOut; // gcolor

    flat in vec3 vertexColor;

    void main(){
        sceneColOut = vertexColor;
    }
#endif