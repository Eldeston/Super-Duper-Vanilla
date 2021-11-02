#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
    }
#endif

#ifdef FRAGMENT
    void main(){
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(0); //gcolor
    }
#endif