#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        gl_Position = ftransform();

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

#ifdef FRAGMENT
    #ifdef VANILLA_SUN_MOON
    #endif
    
    #if USE_SUN_MOON == 1 && defined VANILLA_SUN_MOON
        uniform sampler2D texture;
    #endif
    
    void main(){
        #if USE_SUN_MOON == 1 && defined VANILLA_SUN_MOON
        /* DRAWBUFFERS:2 */
            gl_FragData[0] = vec4(pow(texture2D(texture, texCoord).rgb, vec3(GAMMA)), 1); //gcolor
        #else
            discard;
        #endif
    }
#endif