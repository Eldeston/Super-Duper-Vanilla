#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

INOUT vec4 glcolor;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    void main(){
    /* DRAWBUFFERS:0 */
        gl_FragData[0] = glcolor; //gcolor
    }
#endif