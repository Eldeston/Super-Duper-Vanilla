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
        vec3 linePosStart = vaPosition;
        vec3 linePosEnd = vaPosition + gl_Normal.xyz;

        #ifdef WORLD_CURVATURE
            linePosStart.y -= lengthSquared(linePosStart.xz) / WORLD_CURVATURE_SIZE;
            linePosEnd.y -= lengthSquared(linePosEnd.xz) / WORLD_CURVATURE_SIZE;
        #endif

        // 1.0 - (1.0 / 256.0) = 0.99609375
        linePosStart = mat3(modelViewMatrix) * (linePosStart * 0.99609375) + modelViewMatrix[3].xyz;
        linePosEnd = mat3(modelViewMatrix) * (linePosEnd * 0.99609375) + modelViewMatrix[3].xyz;

        vec2 vertexClipCoord0 = vec2(projectionMatrix[0].x, projectionMatrix[1].y) * linePosStart.xy;
        vec2 vertexClipCoord1 = vec2(projectionMatrix[0].x, projectionMatrix[1].y) * linePosEnd.xy;

        vec2 lineScreenDir = fastNormalize(vertexClipCoord0 / linePosStart.z - vertexClipCoord1 / linePosEnd.z);
        vec2 lineOffset = vec2(lineScreenDir.y * pixelWidth, -lineScreenDir.x * pixelHeight) * linePosStart.z * 2.0;

        if(lineOffset.x < 0) lineOffset = -lineOffset;
        if(gl_VertexID % 2 != 0) lineOffset = -lineOffset;

        gl_Position.xyz = vec3(vertexClipCoord0 + lineOffset, projectionMatrix[3].z + projectionMatrix[2].z * linePosStart.z);
        gl_Position.w = -linePosStart.z;

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