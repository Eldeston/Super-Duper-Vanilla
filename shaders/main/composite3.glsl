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

        uniform mat4 gbufferProjectionInverse;
        
        uniform float centerDepthSmooth;
        uniform float viewWidth;
        uniform float viewHeight;

        #if ANTI_ALIASING == 2
            uniform float frameTimeCounter;
        #endif

        #include "/lib/utility/convertViewSpace.glsl"
    #endif

    void main(){
        #ifdef DOF
            // Get CoC
            float depth = min(1.0, abs(toView(texture2D(depthtex1, texCoord).r) - toView(centerDepthSmooth)) / FOCAL_RANGE);

            // We'll use 15 samples for this blur (1 / 15)
            float currDofLOD = DOF_LOD * depth;
            float blurStepSize = PI2 * 0.0666667;
            vec2 blurRes = 1.0 / (vec2(viewWidth, viewHeight) / exp2(currDofLOD));

            vec3 color = vec3(0);
            for(float x = 0.0; x < PI2; x += blurStepSize){
                // Rotate offsets and sample
                color += texture2D(gcolor, texCoord - vec2(sin(x), cos(x)) * blurRes, currDofLOD).rgb;
            }

            // Add center pixel color
            color += texture2D(gcolor, texCoord, currDofLOD).rgb;
            // 15 samples + 1 sample (1 / 16)
            color *= 0.0625;
        #else
            vec3 color = texture2D(gcolor, texCoord).rgb;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor
    }
#endif