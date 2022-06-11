/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    out vec4 glcolor;

    #if ANTI_ALIASING == 3
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        gl_Position = ftransform();

        #if ANTI_ALIASING == 3
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color;
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    in vec2 texCoord;

    in vec4 glcolor;

    uniform sampler2D texture;

    uniform int renderStage;

    #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT
        #include "/lib/universalVars.glsl"
    #endif
    
    void main(){
        vec4 albedo = texture2D(texture, texCoord);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

    /* DRAWBUFFERS:0 */
        // Detect and calculate the sun and moon
        if(renderStage == MC_RENDER_STAGE_SUN || renderStage == MC_RENDER_STAGE_MOON)
            #if WORLD_SUN_MOON == 1 && SUN_MOON_TYPE == 2 && defined WORLD_LIGHT
                gl_FragData[0] = vec4(pow(albedo.rgb * glcolor.rgb, vec3(GAMMA)) * albedo.a * glcolor.a * SUN_MOON_INTENSITY * SUN_MOON_INTENSITY * LIGHT_COL_DATA_BLOCK, 1);
            #else
                discard;
            #endif
        // Otherwise, calculate skybox
        else gl_FragData[0] = vec4(pow(albedo.rgb * glcolor.rgb, vec3(GAMMA)) * albedo.a * glcolor.a * SKYBOX_BRIGHTNESS, 1);
    }
#endif