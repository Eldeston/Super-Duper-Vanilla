#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

#ifdef VERTEX
    void main(){
        gl_Position = ftransform();
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef FRAGMENT
    // For Optifine to detect
    #ifdef SHARPENING_FILTER
    #endif

    #if (ANTI_ALIASING != 0 && defined SHARPENING_FILTER) || defined CHROMATIC_ABERRATION
        uniform float viewWidth;
        uniform float viewHeight;
    #endif

    #if ANTI_ALIASING != 0 && defined SHARPENING_FILTER
        #include "/lib/post/sharpenFilter.glsl"
    #endif

    uniform sampler2D gcolor;

    void main(){
        vec3 color = texture2D(gcolor, texCoord).rgb;

        #ifdef CHROMATIC_ABERRATION
            vec2 chromaStrength = ABERRATION_PIX_SIZE / vec2(viewWidth, viewHeight);

            color *= vec3(0, 1, 0);
            color.r += texture2D(gcolor, mix(texCoord, vec2(0.5), chromaStrength)).r;
            color.b += texture2D(gcolor, mix(texCoord, vec2(0.5), -chromaStrength)).b;
        #endif

        #if ANTI_ALIASING != 0 && defined SHARPENING_FILTER
            color = sharpenFilter(gcolor, color, texCoord);
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(color, 1); // gcolor
    }
#endif