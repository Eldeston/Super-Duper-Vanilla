/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec4 vertexColor;

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
        uniform int frameMod;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    // Attributes (uses "in" instead of "attribute" because Mojank and GL 330)
    in vec3 vaNormal;
    in vec3 vaPosition;

    in vec4 vaColor;

    void main(){
        // Get vertex color with alpha in linear color space
        vertexColor = vec4(toLinear(vaColor.rgb), vaColor.a);

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

        // View space near-plane clipping
        // Avoid division by near-zero or positive Z which causes wild stretching triangles across screen (Issue #1140)
        const float NEAR_CLIP = -0.05;

        // If both endpoints are behind the near-plane, cull the line segment
        if(linePosStart.z > NEAR_CLIP && linePosEnd.z > NEAR_CLIP){
            gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
            return;
        }

        vec3 p1 = linePosStart;
        vec3 p2 = linePosEnd;

        if(p1.z > NEAR_CLIP){
            float t = (NEAR_CLIP - p1.z) / (p2.z - p1.z);
            p1 = mix(p1, p2, t);
        }
        if(p2.z > NEAR_CLIP){
            float t = (NEAR_CLIP - p1.z) / (p2.z - p1.z);
            p2 = mix(p1, p2, t);
        }

        // Apply slight view scale depth offset like vanilla (0.99609375 = 1.0 - 1.0/256.0)
        vec4 clipStart = projectionMatrix * vec4(p1 * 0.99609375, 1.0);
        vec4 clipEnd = projectionMatrix * vec4(p2 * 0.99609375, 1.0);

        vec3 ndc1 = clipStart.xyz / clipStart.w;
        vec3 ndc2 = clipEnd.xyz / clipEnd.w;

        vec2 lineScreenDir = (ndc2.xy - ndc1.xy) * vec2(1.0 / pixelWidth, 1.0 / pixelHeight);
        float dirLen = length(lineScreenDir);
        if(dirLen > 1e-5){
            lineScreenDir /= dirLen;
        } else {
            lineScreenDir = vec2(1.0, 0.0);
        }

        vec2 lineOffset = vec2(-lineScreenDir.y * pixelWidth, lineScreenDir.x * pixelHeight);

        if(lineOffset.x < 0.0) lineOffset = -lineOffset;
        if(gl_VertexID % 2 != 0) lineOffset = -lineOffset;

        gl_Position = vec4((ndc1.xy + lineOffset) * clipStart.w, clipStart.z, clipStart.w);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec4 sceneColOut; // colortex4

    flat in vec4 vertexColor;

    void main(){
        if(vertexColor.a <= 0.001){ discard; return; }
        sceneColOut = vertexColor;
    }
#endif