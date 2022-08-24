// View matrix uniforms
uniform mat4 gbufferModelViewInverse;

/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    flat out vec3 norm;

    out vec2 texCoord;

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #if defined DOUBLE_VANILLA_CLOUDS
        uniform int instanceId;

        const int countInstances = 2;
    #endif
    
    void main(){
        // Feet player pos
        vec4 vertexPos = gl_Vertex;

        vec2 coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        #ifdef DOUBLE_VANILLA_CLOUDS
            texCoord = instanceId == 1 ? coord : -coord;
            if(instanceId > 0) vertexPos.y += SECOND_CLOUD_HEIGHT * instanceId;
        #else
            texCoord = coord;
        #endif

	    norm = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);
        
        // Clip pos
	    gl_Position = gl_ProjectionMatrix * (gl_ModelViewMatrix * vertexPos);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    flat in vec3 norm;

    in vec2 texCoord;

    // Get albedo texture
    uniform sampler2D texture;

    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #if defined DYNAMIC_CLOUDS || ANTI_ALIASING >= 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    #include "/lib/universalVars.glsl"

    // Get night vision
    uniform float nightVision;

    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/shdDistort.glsl"

    #include "/lib/lighting/simpleShadingForward.glsl"

    void main(){
        // Get albedo alpha
        float albedoAlpha = texture2D(texture, texCoord).a;

        #ifdef DYNAMIC_CLOUDS
            float fade = smootherstep(sin(frameTimeCounter * FADE_SPEED) * 0.5 + 0.5);
            float albedoAlpha2 = texture2D(texture, 0.5 - texCoord).a;
            albedoAlpha = mix(mix(albedoAlpha, albedoAlpha2, fade), max(albedoAlpha, albedoAlpha2), rainStrength);
        #endif

        // Alpha test, discard immediately
        if(albedoAlpha <= ALPHA_THRESHOLD) discard;

        #if WHITE_MODE == 2
            vec4 albedo = vec4(0, 0, 0, albedoAlpha);
        #else
            vec4 albedo = vec4(1, 1, 1, albedoAlpha);
        #endif

        vec4 sceneCol = simpleShadingGbuffers(albedo);

    /* DRAWBUFFERS:03 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(0, 0, 0, 1); // colortex3
    }
#endif