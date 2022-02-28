#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"

varying vec2 texCoord;

varying vec4 glcolor;

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

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    uniform sampler2D texture;

    uniform int renderStage;

    #if USE_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT
        #include "/lib/universalVars.glsl"
    #endif
    
    void main(){
        vec4 albedo = texture2D(texture, texCoord);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

    /* DRAWBUFFERS:0 */
        // Detect and calculate the sun and moon
        if(renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON)
            #if USE_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT
                gl_FragData[0] = vec4(pow(albedo.rgb, vec3(GAMMA)) * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY * sqrt(lightCol), 1);
            #else
                discard;
            #endif
        // Otherwise, calculate skybox
        else gl_FragData[0] = vec4(pow(albedo.rgb * glcolor.rgb, vec3(GAMMA)) * albedo.a * glcolor.a * SKYBOX_BRIGHTNESS, 1);
    }
#endif