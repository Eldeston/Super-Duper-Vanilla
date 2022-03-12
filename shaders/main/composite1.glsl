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
    uniform sampler2D colortex3;

    #ifdef WORLD_LIGHT
        const bool colortex4MipmapEnabled = true;

        uniform sampler2D colortex4;

        uniform float shdFade;
    #endif
    
    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #include "/lib/universalVars.glsl"

    #include "/lib/post/spectral.glsl"

    void main(){
        // Spectral
        float spectralOutline = getSpectral(colortex3, texCoord, 2.0);
        vec3 sceneCol = texture2D(gcolor, texCoord).rgb * (1.0 - spectralOutline) + spectralOutline * EMISSIVE_INTENSITY * 0.5;

        #ifdef WORLD_LIGHT
            #ifdef SHD_ENABLE
                float fogMult = min(1.0, WORLD_FOG_OPACITY * VOL_LIGHT_BRIGHTNESS * (newRainStrength + 1.0 + isEyeInWater * 0.5));
                sceneCol += texture2D(colortex4, texCoord, 1.5).rgb * lightCol * (shdFade * fogMult);
            #else
                float fogMult = min(1.0, WORLD_FOG_OPACITY * VOL_LIGHT_BRIGHTNESS * (newRainStrength + 1.0 + isEyeInWater * 0.5)) * eyeBrightFact;
                sceneCol += texture2D(colortex4, texCoord, 1.5).rgb * lightCol * (shdFade * fogMult) * (isEyeInWater == 1 ? fogColor : vec3(1));
            #endif

        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(sceneCol, 1); // gcolor
        #else
        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(sceneCol, 1); // gcolor
        #endif
    }
#endif