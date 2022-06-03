varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
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
        vec2 dofOffSets[12] = vec2[12](
            vec2(0.8660254, 0.5),
            vec2(0.5, 0.8660254),
            vec2(0, 1),
            vec2(-0.5, 0.8660254),
            vec2(-0.8660254, 0.5),
            vec2(-1, 0),
            vec2(-0.8660254, -0.5),
            vec2(-0.5, -0.8660254),
            vec2(0, -1),
            vec2(0.5, -0.8660254),
            vec2(0.8660254, -0.5),
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

                // We'll use a total of 13 samples for this blur (1 / 13)
                float blurRadius = max(viewWidth, viewHeight) * fovMult * CoC * 0.0769231;
                float currDofLOD = log2(blurRadius);
                vec2 blurRes = blurRadius / vec2(viewWidth, viewHeight);

                // Get center pixel color with LOD
                vec3 dofColor = texture2DLod(gcolor, screenCoord, currDofLOD).rgb;
                for(int x = 0; x < 12; x++){
                    // Rotate offsets and sample
                    dofColor += texture2DLod(gcolor, screenCoord - dofOffSets[x] * blurRes, currDofLOD).rgb;
                }

                // 12 offsetted samples + 1 sample (1 / 13)
                color = dofColor * 0.0769231;
            }
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor
    }
#endif