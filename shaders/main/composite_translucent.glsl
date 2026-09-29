/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: Transparent complex shading and volumetric lighting

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec3 skyCol;

    noperspective out vec2 texCoord;

    #ifdef WORLD_LIGHT
        flat out vec3 sRGBLightCol;
        flat out vec3 lightCol;

        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat out vec3 sRGBSunCol;
            flat out vec3 sunCol;
            flat out vec3 sRGBMoonCol;
            flat out vec3 moonCol;
        #endif
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength, weatherFade;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #if defined WORLD_VANILLA_FOG_COLOR || !defined FORCE_DISABLE_WEATHER
        uniform vec3 fogColor;
    #endif

    void main(){
        // Get buffer texture coordinates
        texCoord = gl_MultiTexCoord0.xy;

        #if !defined FORCE_DISABLE_WEATHER && defined WORLD_LIGHT
            vec3 defaultSkyCol = toLinear(SKY_COLOR_DATA_BLOCK);
            vec3 weatherSkyCol = vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722)));
            skyCol = mix(defaultSkyCol, weatherSkyCol, weatherFade);
        #else
            skyCol = toLinear(SKY_COLOR_DATA_BLOCK);
        #endif

        #ifdef WORLD_LIGHT
            #ifdef FORCE_DISABLE_DAY_CYCLE
                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0;
                lightCol = toLinear(sRGBLightCol);
            #else
                sRGBSunCol = SUN_COL_DATA_BLOCK;
                sunCol = toLinear(sRGBSunCol);
                sRGBMoonCol = MOON_COL_DATA_BLOCK;
                moonCol = toLinear(sRGBMoonCol);

                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK1(sRGBSunCol, sRGBMoonCol);
                lightCol = toLinear(sRGBLightCol);
            #endif
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    flat in vec3 skyCol;

    #ifdef WORLD_LIGHT
        flat in vec3 sRGBLightCol;
        flat in vec3 lightCol;

        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat in vec3 sRGBSunCol;
            flat in vec3 sunCol;
            flat in vec3 sRGBMoonCol;
            flat in vec3 moonCol;
        #endif
    #endif

    noperspective in vec2 texCoord;

    uniform int isEyeInWater;

    uniform float borderFar;

    uniform float nightVision;
    uniform float effectFactor;
    uniform float lightningFlash;
    uniform float darknessLightFactor;

    uniform float fragmentFrameTime;

    uniform vec3 fogColor;

    uniform vec3 cameraPosition;

    uniform mat4 gbufferProjection;
    uniform mat4 gbufferProjectionInverse;

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    uniform mat4 shadowModelView;

    // Main HDR buffer
    uniform sampler2D colortex4;
    uniform sampler2D colortex1;
    // For SSAO and material masks
    uniform sampler2D colortex2;
    uniform sampler2D colortex3;

    uniform sampler2D depthtex0;

    #if ANTI_ALIASING >= 2
        uniform float frameFract;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength, weatherFade;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float dayCycleAdjust;
    #endif

    #if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS
        uniform sampler2D colortex0;

        #if CLOUD_TYPE == 2
            uniform float volumetricCloudFar;

            #include "/lib/rayTracing/volumetricClouds.glsl"
        #endif
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float near;
        uniform float dhNearPlane;

        uniform mat4 dhProjection;
        uniform mat4 dhProjectionInverse;

        uniform sampler2D dhDepthTex0;
    #elif defined VOXY
        uniform mat4 vxProj;
        uniform mat4 vxProjInv;
        uniform int vxRenderDistance;

        uniform sampler2D vxDepthTexOpaque;
        uniform sampler2D vxDepthTexTrans;
    #endif

    #ifdef WORLD_CUSTOM_SKYLIGHT
        const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #include "/lib/utility/projectionFunctions.glsl"

    #if (defined SSR || defined SSGI) && defined PREVIOUS_FRAME
        uniform vec3 camPosDelta;

        uniform mat4 gbufferPreviousModelView;
        uniform mat4 gbufferPreviousProjection;

        uniform sampler2D colortex5;

        #include "/lib/utility/prevProjectionFunctions.glsl"
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        #if defined VOLUMETRIC_LIGHTING && defined SHADOW_MAPPING
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdMapping.glsl"
        #endif

        #include "/lib/rayTracing/volumetricLight.glsl"
    #endif

    #include "/lib/utility/depthTex.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/skyRender.glsl"
    #include "/lib/atmospherics/fogRender.glsl"

    #include "/lib/rayTracing/rayTracer.glsl"

    #include "/lib/lighting/complexShadingDeferred.glsl"

    #if !defined FORCE_DISABLE_CLOUDS && CLOUD_TYPE == 2
        vec3 renderTranslucentClouds(in vec3 sceneCol, in vec3 nFeetPlayerPos, in float feetPlayerDist, in float ditherX, in bool isSky){
            // Get the 1st layer of volumetric clouds position
            vec3 cloudStartPos0 = vec3(cameraPosition.x + fragmentFrameTime, cameraPosition.y - volumetricCloudHeight, cameraPosition.z);

            // Get the volumetric clouds
            vec2 cloudData = volumetricClouds(nFeetPlayerPos, cloudStartPos0, feetPlayerDist, ditherX, isSky);

            #ifdef DOUBLE_LAYERED_CLOUDS
                // Get the 2nd layer of volumetric clouds position by reusing the 1st layer's position
                vec3 cloudStartPos1 = vec3(cloudStartPos0.x + fragmentFrameTime * 0.25, cloudStartPos0.y - SECOND_CLOUD_HEIGHT, cloudStartPos0.z);

                // Variate by swizzling the 2 cloud channels
                cloudData = max(volumetricClouds(nFeetPlayerPos, cloudStartPos1, feetPlayerDist, ditherX, isSky, true).yx, cloudData);
            #endif

            #ifdef DYNAMIC_CLOUDS
                float fadeTime = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);

                float cloudFinal = mix(mix(cloudData.x, cloudData.y, fadeTime), max(cloudData.x, cloudData.y), weatherFade) * 0.125;
            #else
                float cloudFinal = mix(cloudData.x, max(cloudData.x, cloudData.y), weatherFade) * 0.125;
            #endif

            #ifdef FORCE_DISABLE_DAY_CYCLE
                vec3 cloudCelestialLight = lightCol;
            #else
                vec3 cloudCelestialLight = mix(moonCol, sunCol, dayCycleAdjust);
            #endif

            #ifndef FORCE_DISABLE_WEATHER
                cloudCelestialLight *= 1.0 - weatherFade;
                vec3 cloudSkyLight = mix(skyCol, skyCol * 0.35, weatherFade);
            #else
                vec3 cloudSkyLight = skyCol;
            #endif

            vec3 cloudAmbient = vec3(toLinear(nightVision * 0.5 + AMBIENT_LIGHTING) + lightningFlash);
            return mix(sceneCol, cloudAmbient + cloudCelestialLight + cloudSkyLight, cloudFinal);
        }
    #endif

    void getTranslucentSceneDepth(in ivec2 screenTexelCoord, out float depth, out bool isLOD){
        float vanillaDepth = texelFetch(depthtex0, screenTexelCoord, 0).x;
        depth = vanillaDepth;
        isLOD = false;
        #if defined DISTANT_HORIZONS
            if(vanillaDepth == 1.0){
                float dhDepth = texelFetch(dhDepthTex0, screenTexelCoord, 0).x;
                if(dhDepth < 1.0){
                    depth = dhDepth;
                    isLOD = true;
                }
            }
        #elif defined VOXY
            if(vanillaDepth == 1.0){
                float vxOpaque = texelFetch(vxDepthTexOpaque, screenTexelCoord, 0).x;
                float vxTrans = texelFetch(vxDepthTexTrans, screenTexelCoord, 0).x;
                float vxDepth = min(vxOpaque, vxTrans);
                if(vxDepth < 1.0){
                    depth = vxDepth;
                    isLOD = true;
                }
            }
        #endif
    }

    vec3 getTranslucentViewPos(in bool isLOD, in vec3 screenPos){
        #ifdef DISTANT_HORIZONS
            return getViewPos(isLOD ? dhProjectionInverse : gbufferProjectionInverse, screenPos);
        #elif defined VOXY
            if(isLOD){
                vec4 viewPosH = vxProjInv * vec4(screenPos * 2.0 - 1.0, 1.0);
                return viewPosH.xyz / viewPosH.w;
            } else {
                return getViewPos(gbufferProjectionInverse, screenPos);
            }
        #else
            return getViewPos(gbufferProjectionInverse, screenPos);
        #endif
    }

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        bool isLOD;
        float depth;
        getTranslucentSceneDepth(screenTexelCoord, depth, isLOD);

        // Get screen pos
        vec3 screenPos = vec3(texCoord, depth);
        
        vec3 viewPos = getTranslucentViewPos(isLOD, screenPos);

        // Get eye player pos
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        // Get feet player pos
        vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;

        // Get scene color
        sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #if ANTI_ALIASING >= 2
            vec3 dither = fract(getRng3(screenTexelCoord & 255) + frameFract);
        #else
            vec3 dither = getRng3(screenTexelCoord & 255);
        #endif

        // Get view distance
        float viewDot = lengthSquared(viewPos);
        float viewDotInvSqrt = inversesqrt(viewDot);
        float viewDist = viewDot * viewDotInvSqrt;

        // Get normalized eyePlayerPos
        vec3 nEyePlayerPos = eyePlayerPos * viewDotInvSqrt;

        // Get fog factor
        float fogFactor = getFogFactor(viewDist, nEyePlayerPos.y, feetPlayerPos.y + cameraPosition.y);

        // Border fog
        #ifdef BORDER_FOG
            #ifdef VOXY
                float effectiveBorderFar = max(float(vxRenderDistance), borderFar);
                float borderFog = exp2(-exp2(viewDist / effectiveBorderFar * 21.0 - 18.0));
            #elif defined DISTANT_HORIZONS
                float effectiveBorderFar = max(dhRenderDistance, borderFar);
                float borderFog = exp2(-exp2(viewDist / effectiveBorderFar * 21.0 - 18.0));
            #else
                float borderFog = getBorderFog(viewDist);
            #endif
        #else
            float borderFog = 0.0;
        #endif

        // Materials and programs that come after deferred mask
        vec3 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xyz;

        // If the object renders after deferred apply separate lighting
        if(matRaw0.z > 0 && matRaw0.z < 1){
            #if defined SSGI
                const bool needsComplex = true;
            #else
                bool needsComplex = matRaw0.y >= 0.005;
            #endif

            if(needsComplex){
                // Declare and get materials
                vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;
                vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;

                // Apply deferred shading
                sceneColOut = complexShadingDeferred(sceneColOut, screenPos, viewPos, mat3(gbufferModelView) * normal, albedo, dither, viewDotInvSqrt, matRaw0.x, matRaw0.y, isLOD);
            }

            // Get basic sky fog color
            vec3 fogSkyCol = getSkyFogRender(nEyePlayerPos);

            // Border fog
            #ifdef BORDER_FOG
                fogFactor = (fogFactor - 1.0) * borderFog + 1.0;
            #endif

            // Apply fog and darkness fog
            sceneColOut = ((fogSkyCol - sceneColOut) * fogFactor + sceneColOut) * getFogEffectFactor(viewDist);
        }

        #if VOXY_DEBUG == 1
            if(isLOD && depth < 1.0) sceneColOut = mix(sceneColOut, vec3(1.0, 0.2, 0.2), 0.35);
        #endif

        // Apply darkness pulsing effect
        sceneColOut *= 1.0 - darknessLightFactor;

        #if defined WORLD_LIGHT || !defined FORCE_DISABLE_CLOUDS && CLOUD_TYPE == 2
            bool isSky = depth == 1.0;
            float feetPlayerDist = length(feetPlayerPos);
            vec3 nFeetPlayerPos = feetPlayerPos / max(0.0001, feetPlayerDist);
        #endif

        #ifdef WORLD_LIGHT
            // Apply volumetric light
            if(VOLUMETRIC_LIGHTING_STRENGTH != 0 && isEyeInWater != 2)
                sceneColOut += getVolumetricLight(nFeetPlayerPos, feetPlayerDist, fogFactor, borderFog, dither.x, isSky);
        #endif

        #if !defined FORCE_DISABLE_CLOUDS && CLOUD_TYPE == 2
            sceneColOut = renderTranslucentClouds(sceneColOut, nFeetPlayerPos, feetPlayerDist, dither.x, isSky);
        #endif

        // Clamp scene color to prevent NaNs during post processing
        sceneColOut = max(sceneColOut, vec3(0));
    }
#endif