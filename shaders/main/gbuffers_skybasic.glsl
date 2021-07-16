#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
    }
#endif

#ifdef FRAGMENT
    #include "/lib/globalVars/gameUniforms.glsl"
    #include "/lib/globalVars/timeUniforms.glsl"
    #include "/lib/globalVars/universalVars.glsl"

    void main(){
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(lightCol, 1); //gcolor
    }
#endif