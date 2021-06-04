#include "/lib/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/globalVar.glsl"

#include "/lib/globalSamplers.glsl"

INOUT vec2 texcoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    void main(){
        vec3 color = texture2D(BUFFER_VIEW, texcoord).rgb;

        // color = mix(smoothstep(0.1, 0.2, texture2D(colortex2, texcoord).ggg), vec3(1), sqrt(eyeBrightFact));

        gl_FragColor = vec4(pow(color, vec3(1.0 / GAMMA)), 1); //final color
    }
#endif