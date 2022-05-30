varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;

    #ifdef DOF
        const bool gcolorMipmapEnabled = true;

        uniform sampler2D depthtex1;

        uniform mat4 gbufferProjection;
        
        uniform float centerDepthSmooth;
        uniform float viewWidth;
        uniform float viewHeight;

        float fovMult = gbufferProjection[1].y * 0.72794047;
    #endif

    void main(){
        #ifdef DOF
            // CoC calculation by Capt Tatsu from BSL
            float CoC = max(0.0, abs(texture2D(depthtex1, texCoord).r - centerDepthSmooth) * DOF_STRENGTH - 0.01);
            CoC = CoC / sqrt(CoC * CoC + 0.1);

            // We'll use 15 samples for this blur (1 / 15)
            float blurRadius = max(viewWidth, viewHeight) * fovMult * CoC * 0.0666667;
            float currDofLOD = log2(blurRadius);

            // Because we use 15 samples to rotate the sample offsets in the loop we divide by 15 (1 / 15)
            float blurStepSize = PI2 * 0.0666667;
            vec2 blurRes = blurRadius / vec2(viewWidth, viewHeight);

            // Get center pixel color with LOD
            vec3 color = texture2D(gcolor, texCoord, currDofLOD).rgb;
            for(float x = 0.0; x < PI2; x += blurStepSize){
                // Rotate offsets and sample
                color += texture2D(gcolor, texCoord - vec2(cos(x), sin(x)) * blurRes, currDofLOD).rgb;
            }

            // 15 samples + 1 sample (1 / 16)
            color *= 0.0625;
        #else
            vec3 color = texture2D(gcolor, texCoord).rgb;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor
    }
#endif