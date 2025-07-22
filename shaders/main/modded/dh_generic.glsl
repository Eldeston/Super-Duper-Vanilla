/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec4 vertexColor;

    out float vertexViewDist;

    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    void main(){
        // Get vertex color
        vertexColor = gl_Color;

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Output view distance
        vertexViewDist = length(vertexViewPos);

	    #ifdef WORLD_CURVATURE
            // Get vertex feet player position
            vec3 vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

            // Apply curvature distortion
            vertexFeetPlayerPos.y -= lengthSquared(vertexFeetPlayerPos.xz) * worldCurvatureInv;

            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;
        #endif

        // Convert to clip position and output as final position
        // gl_Position = gl_ProjectionMatrix * vertexViewPos;
        gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexViewPos;
        gl_Position.z += gl_ProjectionMatrix[3].z;

        gl_Position.w = -vertexViewPos.z;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    flat in vec4 vertexColor;

    in float vertexViewDist;

    uniform float far;

    void main(){
        // Prevents overdraw
        if(far > vertexViewDist){ discard; return; }

        // Get albedo color
        vec4 albedo = vertexColor;

        // Alpha test, discard and return immediately
        if(albedo.a < ALPHA_THRESHOLD){ discard; return; }

        #if COLOR_MODE == 1
            albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            albedo.rgb = vec3(0);
        #endif

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

        // Apply simple shading
        sceneColOut = albedo.rgb * EMISSIVE_INTENSITY;
    }
#endif