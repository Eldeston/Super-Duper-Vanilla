#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/structs.glsl"

varying vec2 texCoord;

varying vec3 norm;

// View matrix uniforms
uniform mat4 gbufferModelViewInverse;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    uniform mat4 gbufferModelView;

    #if defined DOUBLE_VANILLA_CLOUDS
        uniform int instanceId;

        const int countInstances = 2;
    #endif
    
    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        vec2 coord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        #ifdef DOUBLE_VANILLA_CLOUDS
            texCoord = instanceId == 1 ? coord : -coord;
            if(instanceId > 0) vertexPos.y += SECOND_CLOUD_HEIGHT * instanceId;
        #else
            texCoord = coord;
        #endif

	    norm = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

#ifdef FRAGMENT
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

    #if defined CLOUD_FADE || ANTI_ALIASING == 2
        // Get frame time
        uniform float frameTimeCounter;
    #endif

    #include "/lib/universalVars.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	    posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;
        posVector.feetPlayerPos = posVector.eyePlayerPos + gbufferModelViewInverse[3].xyz;

	    // Declare materials
	    matPBR material;

        float albedoAlpha = texture2D(texture, texCoord).a;
        // Assign normals
        material.normal = norm;

        #ifdef CLOUD_FADE
            float fade = smootherstep(sin(frameTimeCounter * FADE_SPEED) * 0.5 + 0.5);
            float albedoAlpha2 = texture2D(texture, 0.5 - texCoord).a;
            albedoAlpha = mix(albedoAlpha, albedoAlpha2, fade * (1.0 - rainStrength) + albedoAlpha2 * rainStrength);
        #endif

        #if WHITE_MODE == 2
            material.albedo = vec4(0, 0, 0, albedoAlpha);
        #else
            material.albedo = vec4(albedoAlpha);
        #endif

        // Alpha test, discard immediately
        if(material.albedo.a <= ALPHA_THRESHOLD) discard;

        material.metallic = 0.0;
        material.ss = 0.5;
        material.emissive = 0.0;
        material.smoothness = 0.0;
        material.parallaxShd = 1.0;

        // Apply vanilla AO
        material.ambient = 1.0;
        material.light = vec2(0, 1);

        #if ANTI_ALIASING == 2
            vec4 sceneCol = complexShadingGbuffers(material, posVector, toRandPerFrame(getRand1(gl_FragCoord.xy * 0.03125), frameTimeCounter));
        #else
            vec4 sceneCol = complexShadingGbuffers(material, posVector, getRand1(gl_FragCoord.xy * 0.03125));
        #endif

    /* DRAWBUFFERS:03 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(0, 0, 0, 1); //colortex3
    }
#endif