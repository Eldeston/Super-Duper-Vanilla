/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    out float lmCoordX;

    out vec2 texCoord;

    #if ANTI_ALIASING == 3
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        // Lightmap fix for mods
        lmCoordX = saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).x - 0.03125) * 1.06667);
        // Get texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        
	    gl_Position = ftransform();

        #if ANTI_ALIASING == 3
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    in float lmCoordX;

    in vec2 texCoord;

    uniform sampler2D texture;

    #include "/lib/universalVars.glsl"

    // Get night vision
    uniform float nightVision;
    
    void main(){
        vec4 albedo = texture2D(texture, texCoord);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(pow(albedo.rgb, vec3(GAMMA)) * (pow(SKY_COL_DATA_BLOCK, vec3(GAMMA)) + pow((lmCoordX * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B), vec3(GAMMA)) + pow(AMBIENT_LIGHTING + nightVision * 0.5, GAMMA)), albedo.a); // gcolor
    }
#endif