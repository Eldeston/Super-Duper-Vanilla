#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

#include "/lib/globalVars/constants.glsl"
#include "/lib/globalVars/gameUniforms.glsl"

#ifdef DOUBLE_VANILLA_CLOUDS
    #if !defined SHADER_CLOUDS && defined VERTEX
        uniform int instanceId;

        const int countInstances = 2;
    #endif
#endif

INOUT vec2 texcoord;

INOUT vec3 norm;

#ifdef VERTEX
    void main(){
        vec4 vertexPos = gl_Vertex;

        vec2 coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        norm = normalize(gl_NormalMatrix * gl_Normal);

        #ifdef DOUBLE_VANILLA_CLOUDS
            #ifndef SHADER_CLOUDS
                texcoord = instanceId == 1 ? coord : -coord;
                if(instanceId > 0) vertexPos.y += 64.0 * instanceId;
            #endif
        #else
            texcoord = coord;
        #endif

        gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * vertexPos);
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    void main(){
        #ifdef SHADER_CLOUDS
        /* DRAWBUFFERS:0 */
            gl_FragData[0] = vec4(0); //gcolor
        #else
            float alpha = texture2D(texture, texcoord).a;

        /* DRAWBUFFERS:01234 */
            gl_FragData[0] = vec4(1, 1, 1, alpha); //gcolor
            gl_FragData[1] = vec4(norm * 0.5 + 0.5, 1); //colortex1
            gl_FragData[2] = vec4(0, 1, 0.7, 1); //colortex2
            gl_FragData[3] = vec4(0, 0, 1, 1); //colortex3
            gl_FragData[4] = vec4(1, 1, 0, 1); //colortex4
        #endif
    }
#endif