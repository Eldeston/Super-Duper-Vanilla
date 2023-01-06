/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender Studios.

    Copyright (C) 2020 Eldeston


    By downloading this you have agreed to the license and terms of use.
    These can be found inside the included license-file.

    Violating these terms may be penalized with actions according to the Digital Millennium Copyright Act (DMCA),
    the Information Society Directive and/or similar laws depending on your country.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and dynamic clouds

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

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
        // Set the amount of instances, we'll use 2 for now for performance
        const int countInstances = 2;

        // Get current instance id
        uniform int instanceId;
    #endif
    
    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex normal
        vertexNormal = mat3(gbufferModelViewInverse) * fastNormalize(gl_NormalMatrix * gl_Normal);

        // Get vertex position (feet player pos)
        vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        #ifdef DOUBLE_VANILLA_CLOUDS
            // May need to work on this to add more than 2 clouds in the future.
            if(instanceId == 1){
                // If second instance, invert texture coordinates.
                texCoord = -texCoord;
                // Increase cloud height for the second instance.
                vertexPos.y += SECOND_CLOUD_HEIGHT;
            }

            // Convert to clip pos and output as position
	        gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in vec3 vertexNormal;

    in vec2 texCoord;
    
    in vec4 vertexPos;

    // Get albedo texture
    uniform sampler2D tex;

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

    // Get shadow fade
    uniform float shdFade;

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
        float albedoAlpha = textureLod(tex, texCoord, 0).a;

        #ifdef DYNAMIC_CLOUDS
            float fade = smootherstep(sin(frameTimeCounter * FADE_SPEED) * 0.5 + 0.5);
            float albedoAlpha2 = textureLod(tex, 0.5 - texCoord, 0).a;
            albedoAlpha = mix(mix(albedoAlpha, albedoAlpha2, fade), max(albedoAlpha, albedoAlpha2), rainStrength);
        #endif

        // Alpha test, discard immediately
        if(albedoAlpha <= ALPHA_THRESHOLD) discard;

        #if COLOR_MODE == 2
            vec4 albedo = vec4(0, 0, 0, albedoAlpha);
        #else
            vec4 albedo = vec4(1, 1, 1, albedoAlpha);
        #endif

        // Apply simple shading
        vec4 sceneCol = simpleShadingGbuffers(albedo);

    /* DRAWBUFFERS:03 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(0, 0, 0, 1); // colortex3
    }
#endif