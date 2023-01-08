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

/// Buffer features: TAA jittering, and direct shading

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    out float lmCoordX;

    out vec2 texCoord;

    // For Iris/Optifine to detect
    #ifdef WEATHER_ANIMATION
    #endif

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #if defined WEATHER_ANIMATION && !defined FORCE_DISABLE_WEATHER
        // View matrix uniforms
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;

        #if TIMELAPSE_MODE == 2
            // Get smoothed frame time
            uniform float animationFrameTime;

            float newFrameTimeCounter = animationFrameTime;
        #else
            // Get frame time
            uniform float frameTimeCounter;

            float newFrameTimeCounter = frameTimeCounter;
        #endif

        // Position uniforms
        uniform vec3 cameraPosition;

        // Get rain strength
        uniform float rainStrength;

        #include "/lib/vertex/weatherWave.glsl"
    #endif

    void main(){
        // Lightmap fix for mods
        lmCoordX = saturate(gl_MultiTexCoord1.x * 0.00416667);
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        #if defined WEATHER_ANIMATION && !defined FORCE_DISABLE_WEATHER
            if(rainStrength > 0.005){
                // Get vertex position (feet player pos)
                vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

                // Apply weather wave animation
                vertexPos.xz = getWeatherWave(vertexPos.xyz, vertexPos.xz + cameraPosition.xz);

                // Convert to clip pos and output as position
                gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
            }
            else gl_Position = ftransform();
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
    in float lmCoordX;

    in vec2 texCoord;

    // Get albedo texture
    uniform sampler2D tex;

    #include "/lib/universalVars.glsl"

    // Get night vision
    uniform float nightVision;
    
    void main(){
        // Get albedo color
        vec4 albedo = textureLod(tex, texCoord, 0);

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(albedo.rgb * (toLinear(SKY_COL_DATA_BLOCK) + toLinear((lmCoordX * BLOCKLIGHT_I * 0.00392156863) * vec3(BLOCKLIGHT_R, BLOCKLIGHT_G, BLOCKLIGHT_B)) + toLinear(AMBIENT_LIGHTING + nightVision * 0.5)), albedo.a); // gcolor
    }
#endif