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

    #if BLOOM == 1
        uniform sampler2D colortex3;
    #endif

    #include "/lib/globalVars/gameUniforms.glsl"
    #include "/lib/globalVars/timeUniforms.glsl"
    #include "/lib/globalVars/universalVars.glsl"

    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    void main(){
        vec3 sceneCol = texture2D(gcolor, texcoord).rgb;

        #if BLOOM == 1
            vec3 bloomCol = sceneCol * texture2D(colortex3, texcoord).g;
        #elif BLOOM == 2
            vec3 bloomCol = sceneCol;
        #endif

        float fogMult = FOG_OPACITY * VOL_LIGHT_BRIGHTNESS * (1.0 + isEyeInWater * 0.32);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(sceneCol + (texture2D(colortex4, texcoord, 1.6).rgb * fogMult) * lightCol, 1); //gcolor

        #if BLOOM == 1
        /* DRAWBUFFERS:02 */
            // Compress the HDR colors
            gl_FragData[1] = vec4(bloomCol / (1.0 + bloomCol), 1); //colortex2
        #elif BLOOM == 2
        /* DRAWBUFFERS:02 */
            // Compress the HDR colors
            gl_FragData[1] = vec4(sceneCol / (1.0 + sceneCol), 1); //colortex2
        #endif
    }
#endif