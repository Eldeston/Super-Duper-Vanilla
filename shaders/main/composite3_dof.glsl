/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: DOF blur

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef DOF
        flat out float fovMult;

        noperspective out vec2 texCoord;

        uniform mat4 gbufferProjection;
    #endif

    void main(){
        #ifdef DOF
            // Get buffer texture coordinates
            texCoord = gl_MultiTexCoord0.xy;

            fovMult = gbufferProjection[1].y * 0.04549628; // 0.72794047 * 0.0625
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    uniform sampler2D colortex4;

    #ifdef DOF
        // Needs to be enabled by force to be able to use LOD fully even with textureLod
        const bool gcolorMipmapEnabled = true;

        // Precalculated dof offsets by vec2(cos(x), sin(x))
        const vec2 dofOffSets[15] = vec2[15](
            vec2(0.91354546, 0.40673664),
            vec2(0.66913061, 0.74314483),
            vec2(0.30901699, 0.95105652),
            vec2(-0.10452846, 0.99452190),
            vec2(-0.5, 0.86602540),
            vec2(-0.80901699, 0.58778525),
            vec2(-0.97814760, 0.20791169),
            vec2(-0.97814760, -0.20791169),
            vec2(-0.80901699, -0.58778525),
            vec2(-0.5, -0.86602540),
            vec2(-0.10452846, -0.99452190),
            vec2(0.30901699, -0.95105652),
            vec2(0.66913061, -0.74314483),
            vec2(0.91354546, -0.40673664),
            vec2(1, 0)
        );

        flat in float fovMult;

        noperspective in vec2 texCoord;

        uniform float viewWidth;
        uniform float viewHeight;
        uniform float centerDepthSmooth;

        uniform sampler2D depthtex1;
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        // Get scene color
        sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #ifdef DOF
            // Declare and get positions
            float depth = texelFetch(depthtex1, screenTexelCoord, 0).x;

            // Return immediately if player hand
            if(depth <= 0.56) return;
            
            // CoC calculation by Capt Tatsu from BSL
            float CoC = max(0.0, abs(depth - centerDepthSmooth) * DOF_STRENGTH - 0.01);
            CoC = CoC * inversesqrt(CoC * CoC + 0.1);

            // We'll use a total of 16 samples for this blur (1 / 16)
            float blurRadius = min(viewWidth, viewHeight) * fovMult * CoC;
            float currDofLOD = log2(blurRadius);
            vec2 blurRes = blurRadius / vec2(viewWidth, viewHeight);

            // Get center pixel color with LOD
            vec3 dofColor = textureLod(colortex4, texCoord, currDofLOD).rgb;
            for(uint i = 0u; i < 15u; i++){
                // Rotate offsets and sample
                dofColor += textureLod(colortex4, texCoord - dofOffSets[i] * blurRes, currDofLOD).rgb;
            }

            // 15 offsetted samples + 1 sample (1 / 16)
            sceneColOut = dofColor * 0.0625;
        #endif
    }
#endif