#include "/lib/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

INOUT vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

#ifdef VERTEX
    void main() {
        gl_Position = ftransform();
        starData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
    }
#endif

#ifdef FRAGMENT
    void main(){
    /* DRAWBUFFERS:034 */
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0); //gcolor
        gl_FragData[1] = vec4(0.0, 1.0, 0.0, 1.0); //colortex3
        gl_FragData[2] = vec4(0.0, 0.0, 1.0, 1.0); //colortex3
    }
#endif