#include "/lib/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
    }
#endif

#ifdef FRAGMENT
    void main(){
    /* DRAWBUFFERS:034 */
        gl_FragData[0] = vec4(0, 0, 0, 1); //gcolor
        gl_FragData[1] = vec4(0, 1, 0, 1); //colortex3
        gl_FragData[2] = vec4(0, 0, 1, 1); //colortex4
    }
#endif