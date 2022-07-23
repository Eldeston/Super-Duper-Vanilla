/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    out vec2 screenCoord;

    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    in vec2 screenCoord;

    uniform sampler2D gcolor;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #ifdef DOF
        const bool gcolorMipmapEnabled = true;

        uniform sampler2D depthtex1;

        uniform mat4 gbufferProjection;
        
        uniform float centerDepthSmooth;

        float fovMult = gbufferProjection[1].y * 0.72794047;

        // Precalculated dof offsets by vec2(cos(x), sin(x))
        vec2 dofOffSets[8] = vec2[8](
            vec2(0.707106781187),
            vec2(0, 1),
            vec2(-0.707106781187, 0.707106781187),
            vec2(-1, 0),
            vec2(-0.707106781187),
            vec2(0, -1),
            vec2(0.707106781187, -0.707106781187),
            vec2(1, 0)
        );
    #endif

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);
        // Original color
        vec3 color = texelFetch(gcolor, screenTexelCoord, 0).rgb;

        #ifdef DOF
            // Get depth
            float depth = texelFetch(depthtex1, screenTexelCoord, 0).x;

            // If not hand, do DOF
            if(depth > 0.56){
                // CoC calculation by Capt Tatsu from BSL
                float CoC = max(0.0, abs(depth - centerDepthSmooth) * DOF_STRENGTH - 0.01);
                CoC = CoC / sqrt(CoC * CoC + 0.1);

                // We'll use a total of 12 samples for this blur (1 / 8)
                float blurRadius = max(viewWidth, viewHeight) * fovMult * CoC * 0.125;
                float currDofLOD = log2(blurRadius);
                vec2 blurRes = blurRadius / vec2(viewWidth, viewHeight);

                // Get center pixel color with LOD
                vec3 dofColor = vec3(0);
                for(int x = 0; x < 8; x++){
                    // Rotate offsets and sample
                    dofColor += texture2DLod(gcolor, screenCoord - dofOffSets[x] * blurRes, currDofLOD).rgb;
                }

                // 12 offsetted samples (1 / 8)
                color = dofColor * 0.125;
            }
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor
    }
#endif