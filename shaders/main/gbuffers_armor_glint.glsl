#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

varying vec3 norm;

varying vec4 glcolor;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    uniform mat4 gbufferModelViewInverse;

    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	    norm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
        
	    gl_Position = ftransform();

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    void main(){
        vec4 albedo = texture2D(texture, texCoord);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

        #if WHITE_MODE == 0
            albedo.rgb *= glcolor.rgb;
        #elif WHITE_MODE == 1
            albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            albedo.rgb = glcolor.rgb;
        #endif

        float emissive = getLuminance(albedo.rgb);
        albedo.rgb = pow(albedo.rgb, vec3(GAMMA));

    /* DRAWBUFFERS:012 */
        gl_FragData[0] = vec4(albedo.rgb * (1.0 + emissive * EMISSIVE_INTENSITY), albedo.a); //gcolor
        gl_FragData[1] = vec4(norm * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(albedo.rgb, 1); //colortex2
    }
#endif