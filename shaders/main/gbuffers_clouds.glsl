/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    flat out vec3 vertexNormal;

    out vec2 texCoord;

    out vec4 vertexPos;

    // View matrix uniforms
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef DOUBLE_VANILLA_CLOUDS
        // Set the amount of instances, we'll use 2 for now
        int countInstances = 2;

        // Get current instance id
        uniform int instanceId;
    #endif
    
    void main(){
        // Get texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex normal
        vertexNormal = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);

        // Get vertex position (feet player pos)
        vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        #ifdef DOUBLE_VANILLA_CLOUDS
            // May need to work on this to add more than 2 clouds in the future.
            if(instanceId == 2){
                // If second instance, invert texture coordinates.
                texCoord = -texCoord;
                // Increase cloud height for the second instance.
                vertexPos.y += SECOND_CLOUD_HEIGHT;
            }
        #endif
        
        // Clip pos
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    flat in vec3 vertexNormal;

    in vec2 texCoord;
    
    in vec4 vertexPos;

    // Get albedo texture
    uniform sampler2D texture;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif

    // Get night vision
    uniform float nightVision;

    #if defined DYNAMIC_CLOUDS || ANTI_ALIASING >= 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    #include "/lib/universalVars.glsl"

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