/*
================================ /// Super Duper Vanilla v1.3.4 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.4 /// ================================
*/

/// Buffer features: DOF blur

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out float fovMult;

    out vec2 texCoord;

    uniform mat4 gbufferProjection;

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;

        fovMult = gbufferProjection[1].y * 0.72794047;

        gl_Position = ftransform();
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in float fovMult;

    in vec2 texCoord;

    uniform sampler2D gcolor;

    #ifdef DOF
        // Needs to be enabled by force to be able to use LOD fully even with textureLod
        const bool gcolorMipmapEnabled = true;

        // Precalculated dof offsets by vec2(cos(x), sin(x))
        const vec2 dofOffSets[9] = vec2[9](
            vec2(0.76604444, 0.64278761),
            vec2(0.17364818, 0.98480775),
            vec2(-0.5, 0.86602540),
            vec2(-0.93969262, 0.34202014),
            vec2(-0.93969262, -0.34202014),
            vec2(-0.5, -0.86602540),
            vec2(0.17364818, -0.98480775),
            vec2(0.76604444, -0.64278761),
            vec2(1, 0)
        );

        uniform float centerDepthSmooth;

        uniform float viewWidth;
        uniform float viewHeight;

        uniform sampler2D depthtex1;
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Get scene color
        vec3 sceneCol = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        #ifdef DOF
            // Declare and get positions
            float depth = texelFetch(depthtex1, screenTexelCoord, 0).x;

            // Apply DOF if not player hand
            if(depth > 0.56){
                // CoC calculation by Capt Tatsu from BSL
                float CoC = max(0.0, abs(depth - centerDepthSmooth) * DOF_STRENGTH - 0.01);
                CoC = CoC * inversesqrt(CoC * CoC + 0.1);

                // We'll use a total of 10 samples for this blur (1 / 10)
                float blurRadius = max(viewWidth, viewHeight) * fovMult * CoC * 0.1;
                float currDofLOD = log2(blurRadius);
                vec2 blurRes = blurRadius / vec2(viewWidth, viewHeight);

                // Get center pixel color with LOD
                vec3 dofColor = textureLod(gcolor, texCoord, currDofLOD).rgb;
                for(int x = 0; x < 9; x++){
                    // Rotate offsets and sample
                    dofColor += textureLod(gcolor, texCoord - dofOffSets[x] * blurRes, currDofLOD).rgb;
                }

                // 9 offsetted samples + 1 sample (1 / 10)
                sceneCol = dofColor * 0.1;
            }
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol, 1); // gcolor
    }
#endif