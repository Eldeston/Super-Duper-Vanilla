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

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod8;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    // Attributes (uses "in" instead of "attribute" because Mojank and GL 330)
    in vec3 vaNormal;
    in vec3 vaPosition;

    in vec4 vaColor;

    void main(){
        // Get vertex color
        vertexColor = vaColor.rgb;

        // Feet player pos
        vec3 linePosStart = mat3(modelViewMatrix) * vaPosition + modelViewMatrix[3].xyz;
        vec3 linePosEnd = mat3(modelViewMatrix) * (vaPosition + vaNormal) + modelViewMatrix[3].xyz;

        #ifdef WORLD_CURVATURE
            linePosStart = mat3(gbufferModelViewInverse) * linePosStart;
            linePosEnd = mat3(gbufferModelViewInverse) * linePosEnd;

            linePosStart.y -= lengthSquared(linePosStart.xz + gbufferModelViewInverse[3].xz) * worldCurvatureInv;
            linePosEnd.y -= lengthSquared(linePosEnd.xz + gbufferModelViewInverse[3].xz) * worldCurvatureInv;

            linePosStart = mat3(gbufferModelView) * linePosStart;
            linePosEnd = mat3(gbufferModelView) * linePosEnd;
        #endif

        vec2 vertexClipCoordStart = vec2(projectionMatrix[0].x, projectionMatrix[1].y) * linePosStart.xy;
        vec2 vertexClipCoordEnd = vec2(projectionMatrix[0].x, projectionMatrix[1].y) * linePosEnd.xy;

        vec2 lineScreenDir = fastNormalize(vertexClipCoordStart / linePosStart.z - vertexClipCoordEnd / linePosEnd.z);
        vec2 lineOffset = vec2(-lineScreenDir.y * pixelWidth, lineScreenDir.x * pixelHeight);

        if(lineOffset.x < 0) lineOffset = -lineOffset;
        if(gl_VertexID % 2 != 0) lineOffset = -lineOffset;

        // Apply view scaling here
        // 1.0 - (1.0 / 256.0) = 0.99609375
        float vertexViewDepth = linePosStart.z * 0.99609375;
        float vertexClipDepth = projectionMatrix[2].z * vertexViewDepth + projectionMatrix[3].z;

        gl_Position.xyz = vec3(vertexClipCoordStart - lineOffset * (vertexViewDepth * 2.0), vertexClipDepth);
        gl_Position.w = -vertexViewDepth;

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