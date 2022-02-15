#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/structs.glsl"

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
    }
#endif

#ifdef FRAGMENT
    // Get world time
    uniform float day;
    uniform float dawnDusk;
    uniform float twilight;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float rainStrength;

    uniform ivec2 eyeBrightnessSmooth;

    uniform vec3 fogColor;

    #include "/lib/universalVars.glsl"

    void main(){
    /* DRAWBUFFERS:07 */
        gl_FragData[0] = vec4(skyCol, 1); //gcolor
    }
#endif