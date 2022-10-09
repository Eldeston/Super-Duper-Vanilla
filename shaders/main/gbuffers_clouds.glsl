/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out vec3 shdLightView;

        #ifdef SHD_ENABLE
            out vec3 shdPos;

            out float distortFactor;
        #endif
    #endif

    flat out vec3 vertexNormal;

    out vec2 texCoord;


    // View matrix uniforms
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdDistort.glsl"
        #endif
    #endif

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #ifdef DOUBLE_VANILLA_CLOUDS
        // Set the amount of instances, we'll use 2 for now
        const int countInstances = 2;

        // Get current instance id
        uniform int instanceId;
    #endif
    
    void main(){
        // Get texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        // Get vertex normal (view space)
        vertexNormal = normalize(gl_NormalMatrix * gl_Normal);

        // Get feet player pos
        vec4 feetPlayerPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        #ifdef WORLD_LIGHT
            // Shadow light view matrix
            shdLightView = mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);

            #ifdef SHD_ENABLE
                // Get shadow clip space pos
                shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos.xyz + shadowModelView[3].xyz) + shadowProjection[3].xyz;
                // Get distortion factor
                distortFactor = getDistortFactor(shdPos.xy);

                // Bias mutilplier, adjusts according to the current shadow distance and resolution
				float biasAdjustMult = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.25;

                // Apply shadow bias
                shdPos += (mat3(shadowProjection) * (mat3(shadowModelView) * (mat3(gbufferModelViewInverse) * vertexNormal))) * distortFactor * biasAdjustMult;
            #endif
        #endif

        #ifdef DOUBLE_VANILLA_CLOUDS
            // May need to work on this to add more than 2 clouds in the future.
            if(instanceId == 2){
                // If second instance, invert texture coordinates.
                texCoord = -texCoord;
                // Increase cloud height for the second instance.
                feetPlayerPos.y += SECOND_CLOUD_HEIGHT;
            }
        #endif
        
        // Clip pos
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * feetPlayerPos);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    #ifdef WORLD_LIGHT
        flat in vec3 shdLightView;

        #ifdef SHD_ENABLE
            in vec3 shdPos;

            in float distortFactor;
        #endif
    #endif

    flat in vec3 vertexNormal;

    in vec2 texCoord;

    // Get albedo texture
    uniform sampler2D texture;

    // Get night vision
    uniform float nightVision;

    #if defined DYNAMIC_CLOUDS || ANTI_ALIASING >= 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    #include "/lib/universalVars.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/lighting/shdMapping.glsl"

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