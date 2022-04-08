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
    uniform sampler2D texture;

    #include "/lib/universalVars.glsl"
    
    void main(){
        vec4 albedo = texture2D(texture, texCoord);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(pow(albedo.rgb, vec3(GAMMA)) * (skyCol + ambientLighting + lightCol), albedo.a); //gcolor
    }
#endif