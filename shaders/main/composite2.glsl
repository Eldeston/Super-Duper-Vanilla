#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

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

        #include "/lib/utility/noiseFunctions.glsl"
    #endif

    void main(){
        #ifdef DOF
            float depth = min(1.0, abs(toView(texture2D(depthtex1, texCoord).r) - toView(centerDepthSmooth)) / FOCAL_RANGE);

            #if ANTI_ALIASING == 2
                float dither = toRandPerFrame(getRand1(gl_FragCoord.xy * 0.03125), frameTimeCounter) * PI2;
            #else
                float dither = getRand1(gl_FragCoord.xy * 0.03125) * PI2;
            #endif

            vec2 randVec = (vec2(sin(dither), cos(dither)) * depth) / (vec2(viewWidth, viewHeight) / exp2(DOF_LOD));
            
            vec3 color = texture2D(gcolor, texCoord + randVec).rgb;
            color = (color + texture2D(gcolor, texCoord - randVec).rgb) * 0.5;
        #else
            vec3 color = texture2D(gcolor, texCoord).rgb;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); //gcolor
    }
#endif