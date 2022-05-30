varying vec2 screenCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        screenCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D gcolor;
    uniform sampler2D colortex3;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #ifdef DOF
        const bool gcolorMipmapEnabled = true;

        uniform sampler2D depthtex1;

        uniform mat4 gbufferProjection;
        
        uniform float centerDepthSmooth;

        float fovMult = gbufferProjection[1].y * 0.72794047;

        float getDepthBlur(vec2 pixSize){
            // Apply simple box blur
            return (texture2D(depthtex1, screenCoord - pixSize).x + texture2D(depthtex1, screenCoord + pixSize).x +
                texture2D(depthtex1, screenCoord - vec2(pixSize.x, -pixSize.y)).x + texture2D(depthtex1, screenCoord + vec2(pixSize.x, -pixSize.y)).x) * 0.25;
        }
    #endif

    float getSpectral(vec2 pixSize){
        // Do a simple blur
        float totalDepth = texture2D(colortex3, screenCoord + pixSize).z + texture2D(colortex3, screenCoord - pixSize).z +
            texture2D(colortex3, screenCoord + vec2(pixSize.x, -pixSize.y)).z + texture2D(colortex3, screenCoord - vec2(pixSize.x, -pixSize.y)).z;

        // Get the difference between the blurred samples and original
        return abs(totalDepth * 0.25 - texture2D(colortex3, screenCoord).z);
    }

    void main(){
        // Pixel size
        vec2 pixSize = 1.0 / vec2(viewWidth, viewHeight);
        // Original color
        vec3 color = texture2D(gcolor, screenCoord).rgb;

        #ifdef DOF
            // Get depth
            float depth = texture2D(depthtex1, screenCoord).x;

            // If not hand, do DOF
            if(depth > 0.56){
                // CoC calculation by Capt Tatsu from BSL
                float CoC = max(0.0, abs(depth - centerDepthSmooth) * DOF_STRENGTH - 0.01);
                CoC = CoC / sqrt(CoC * CoC + 0.1);

                // We'll use 12 samples for this blur (1 / 12)
                float blurRadius = max(viewWidth, viewHeight) * fovMult * CoC * 0.0833333;
                float currDofLOD = log2(blurRadius);

                // Because we use 12 samples to rotate the sample offsets in the loop we divide by 12 (1 / 12)
                float blurStepSize = PI2 * 0.0833333;
                vec2 blurRes = blurRadius * pixSize;

                // Get center pixel color with LOD
                vec3 dofColor = texture2DLod(gcolor, screenCoord, currDofLOD).rgb;
                for(float x = 0.0; x < PI2; x += blurStepSize){
                    // Rotate offsets and sample
                    dofColor += texture2DLod(gcolor, screenCoord - vec2(cos(x), sin(x)) * blurRes, currDofLOD).rgb;
                }

                // 12 samples + 1 sample (1 / 13)
                color = dofColor * 0.0769231;
            }
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color + getSpectral(pixSize) * EMISSIVE_INTENSITY, 1); // gcolor
    }
#endif