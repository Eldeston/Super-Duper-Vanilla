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
    uniform sampler2D colortex3;
    uniform sampler2D colortex4;

    #include "/lib/globalVars/gameUniforms.glsl"
    #include "/lib/globalVars/screenUniforms.glsl"
    #include "/lib/globalVars/timeUniforms.glsl"
    #include "/lib/globalVars/universalVars.glsl"

    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    void main(){
        vec3 sceneCol = texture2D(gcolor, texcoord).rgb;
        vec3 color = sceneCol * texture2D(colortex3, texcoord).g;

        float volMult = VOL_LIGHT_BRIGHTNESS * (1.0 - newTwilight) * (1.0 - blindness * 0.6) * (0.25 * (1.0 - eyeBrightFact) + eyeBrightFact) * min(1.0, FOG_OPACITY + rainMult * underWaterMult * 0.1);

    /* DRAWBUFFERS:02 */
        gl_FragData[0] = vec4(sceneCol + (texture2D(colortex4, texcoord, 1.6).gba * volMult) * lightCol, 1); //gcolor
        // Compress the HDR colors
        gl_FragData[1] = vec4(color / (1.0 + color), 1); //colortex2
    }
#endif