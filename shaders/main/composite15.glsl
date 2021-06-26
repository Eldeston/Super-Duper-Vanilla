#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/screenUniforms.glsl"
#include "/lib/globalVars/texUniforms.glsl"

#include "/lib/post/fxaa.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        #ifdef FXAA
            vec3 currCol = textureFXAA(gcolor, texcoord, vec2(viewWidth, viewHeight)).rgb;

        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(currCol, 1); //gcolor
        #endif
    }
#endif