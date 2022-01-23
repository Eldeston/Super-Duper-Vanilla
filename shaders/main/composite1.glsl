#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    const bool colortex4MipmapEnabled = true;

    uniform sampler2D gcolor;
    uniform sampler2D colortex4;

    #ifdef BLOOM
        uniform sampler2D colortex3;
    #endif

    uniform int isEyeInWater;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    uniform float nightVision;
    uniform float rainStrength;

    uniform float day;
    uniform float dawnDusk;
    uniform float twilight;

    uniform ivec2 eyeBrightnessSmooth;

    uniform vec3 fogColor;

    #include "/lib/universalVars.glsl"

    #include "/lib/post/spectral.glsl"

    void main(){
        // Spectral
        float spectralOutline = getSpectral(colortex4, texcoord, 2.0);
        vec3 sceneCol = texture2D(gcolor, texcoord).rgb * (1.0 - spectralOutline) + spectralOutline * 2.0;

        #ifdef ENABLE_LIGHT
            #ifdef SHD_ENABLE
                float fogMult = min(1.0, FOG_OPACITY * VOL_LIGHT_BRIGHTNESS * (rainMult + isEyeInWater * 0.256));
            #else
                float fogMult = min(1.0, FOG_OPACITY * VOL_LIGHT_BRIGHTNESS * (rainMult + isEyeInWater * 0.256)) * eyeBrightFact;
            #endif

            sceneCol += texture2D(colortex4, texcoord, 1.5).rgb * (lightCol * fogMult);

        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(sceneCol, 1); // gcolor
        #else
        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(sceneCol, 1); // gcolor
        #endif

        #ifdef BLOOM
        /* DRAWBUFFERS:02 */
            // Compress the HDR colors
            gl_FragData[1] = vec4(sceneCol / (sceneCol + 1.0), 1); // colortex2
        #endif
    }
#endif