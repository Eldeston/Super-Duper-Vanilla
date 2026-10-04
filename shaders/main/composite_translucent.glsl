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
        flat out vec3 sRGBLightCol, lightCol;
        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat out vec3 sRGBSunCol, sunCol, sRGBMoonCol, moonCol;
        #endif
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength, weatherFade;
        #if WORLD_ID == 0
            #ifndef THUNDER_STRENGTH_DECLARED
                #define THUNDER_STRENGTH_DECLARED
                uniform float thunderStrength;
            #endif
        #endif
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
            #if WORLD_ID == 0
                float effectiveWeatherFade = clamp(max(weatherFade, thunderStrength), 0.0, 1.0);
            #else
                float effectiveWeatherFade = weatherFade;
            #endif
            vec3 defaultSkyCol = toLinear(SKY_COLOR_DATA_BLOCK);
            vec3 weatherSkyCol = vec3(dot(toLinear(fogColor), vec3(0.2126, 0.7152, 0.0722)));
            skyCol = mix(defaultSkyCol, weatherSkyCol, effectiveWeatherFade);
        #else
            skyCol = toLinear(SKY_COLOR_DATA_BLOCK);
        #endif

        #ifdef WORLD_LIGHT
            #ifndef FORCE_DISABLE_WEATHER
                float cVis = 1.0 - effectiveWeatherFade;
            #else
                const float cVis = 1.0;
            #endif
            #ifdef FORCE_DISABLE_DAY_CYCLE
                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0 * cVis; lightCol = toLinear(sRGBLightCol);
            #else
                sRGBSunCol = SUN_COLOR_BASE * cVis; sunCol = toLinear(SUN_COL_DATA_BLOCK);
                sRGBMoonCol = MOON_COLOR_BASE * cVis; moonCol = toLinear(MOON_COL_DATA_BLOCK);
                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK1(sRGBSunCol, sRGBMoonCol); lightCol = toLinear(sRGBLightCol);
            #endif
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif
#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    flat in vec3 skyCol;
    #ifdef WORLD_LIGHT
        flat in vec3 sRGBLightCol, lightCol;
        #ifndef FORCE_DISABLE_DAY_CYCLE
            flat in vec3 sRGBSunCol, sunCol, sRGBMoonCol, moonCol;
        #endif
    #endif

    #if WORLD_ID == 1
        #ifndef END_FLASH_UNIFORM_DECLARED
            #define END_FLASH_UNIFORM_DECLARED
            uniform float endFlashIntensity;
            uniform vec3 endFlashPosition;
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
    uniform float fogStart;
    uniform float fogEnd;
    uniform vec3 cameraPosition;
    uniform mat4 gbufferProjection, gbufferProjectionInverse;
    uniform mat4 gbufferModelView, gbufferModelViewInverse;
    uniform mat4 shadowModelView;
    // Main HDR buffer, normals, SSAO and material masks
    uniform sampler2D colortex4, colortex1, colortex2, colortex3;

    uniform sampler2D depthtex0;
    #if defined GODRAYS && GODRAYS_WATER_TRANSMISSION == 1
        uniform sampler2D depthtex1;
    #endif

    #if ANTI_ALIASING >= 2
        uniform float frameFract;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength, weatherFade;
        #if WORLD_ID == 0
            #ifndef THUNDER_STRENGTH_DECLARED
                #define THUNDER_STRENGTH_DECLARED
                uniform float thunderStrength;
            #endif
        #endif
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float dayCycleAdjust;
    #endif

    #if (CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS) || defined GODRAYS
        #ifndef COLORTEX0_DECLARED
            #define COLORTEX0_DECLARED
            uniform sampler2D colortex0;
        #endif

        #if CLOUD_TYPE == 2 && !defined FORCE_DISABLE_CLOUDS
            uniform float volumetricCloudFar;

            #include "/lib/rayTracing/volumetricClouds.glsl"
        #endif
    #endif

    #ifdef DISTANT_HORIZONS
        uniform float near, dhNearPlane;
        uniform mat4 dhProjection, dhProjectionInverse;
        uniform sampler2D dhDepthTex0;
    #elif defined VOXY
        uniform mat4 vxProj, vxProjInv;
        uniform int vxRenderDistance;
        uniform sampler2D vxDepthTexOpaque, vxDepthTexTrans;
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

        #if defined SHADOW_MAPPING && (defined VOLUMETRIC_LIGHTING || defined RAINBOW)
            #ifndef SHADOW_PROJECTION_DECLARED
                #define SHADOW_PROJECTION_DECLARED
                uniform mat4 shadowProjection;
            #endif

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

    #if defined WORLD_LIGHT && defined GODRAYS
        #include "/lib/atmospherics/godrays.glsl"
    #endif

    #if !defined FORCE_DISABLE_CLOUDS && CLOUD_TYPE == 2
        vec3 renderTranslucentClouds(in vec3 sceneCol, in vec3 nFeetPlayerPos, in float feetPlayerDist, in float ditherX, in bool isSky){
            #ifndef FORCE_DISABLE_WEATHER
                #if WORLD_ID == 0
                    float cloudWeatherFade = clamp(max(weatherFade, thunderStrength), 0.0, 1.0);
                #else
                    float cloudWeatherFade = weatherFade;
                #endif
                #ifdef DYNAMIC_WEATHER
                    if(cloudWeatherFade <= 0.001) return sceneCol;
                #endif
            #endif
            // Get the 1st layer of volumetric clouds position
            vec3 cloudStartPos0 = vec3(cameraPosition.x + fragmentFrameTime, cameraPosition.y - volumetricCloudHeight, cameraPosition.z);
            // Get the volumetric clouds
            vec2 cloudData = volumetricClouds(nFeetPlayerPos, cloudStartPos0, feetPlayerDist, ditherX, isSky);

            #ifdef DOUBLE_LAYERED_CLOUDS
                #ifndef FORCE_DISABLE_WEATHER
                    if(cloudWeatherFade < 0.65 && cloudWeatherFade > 0.001){
                        // Get the 2nd layer of volumetric clouds position by reusing the 1st layer's position
                        vec3 cloudStartPos1 = vec3(cloudStartPos0.x + fragmentFrameTime * 0.25, cloudStartPos0.y - SECOND_CLOUD_HEIGHT, cloudStartPos0.z);
                        // Fade cirrus with cloud presence at low overcast, and hide completely when overcast
                        float cirrusFactor = smoothstep(0.0, 0.20, cloudWeatherFade) * (1.0 - smoothstep(0.30, 0.65, cloudWeatherFade));
                        // Variate by swizzling the 2 cloud channels
                        cloudData = max(volumetricClouds(nFeetPlayerPos, cloudStartPos1, feetPlayerDist, ditherX, isSky, true).yx * cirrusFactor, cloudData);
                    }
                #else
                    // Get the 2nd layer of volumetric clouds position by reusing the 1st layer's position
                    vec3 cloudStartPos1 = vec3(cloudStartPos0.x + fragmentFrameTime * 0.25, cloudStartPos0.y - SECOND_CLOUD_HEIGHT, cloudStartPos0.z);
                    // Variate by swizzling the 2 cloud channels
                    cloudData = max(volumetricClouds(nFeetPlayerPos, cloudStartPos1, feetPlayerDist, ditherX, isSky, true).yx, cloudData);
                #endif
            #endif

            if(cloudData.x <= 0.0001 && cloudData.y <= 0.0001) return sceneCol;

            #ifdef DYNAMIC_CLOUDS
                float fadeTime = saturate(sin(fragmentFrameTime * FADE_SPEED) * 0.8 + 0.5);

                float baseCumulus = mix(cloudData.x, cloudData.y, fadeTime);
            #else
                float baseCumulus = cloudData.x;
            #endif

            #ifndef FORCE_DISABLE_WEATHER
                #ifdef DYNAMIC_WEATHER
                    #ifdef STORY_MODE_CLOUDS
                        float cloudPresence = smoothstep(0.0, 0.25, cloudWeatherFade);
                        float expandedCumulus = mix(baseCumulus, max(cloudData.x, cloudData.y), cloudWeatherFade) * cloudPresence;
                        float cloudFinal = expandedCumulus * 0.125;
                    #else
                        // Scale cumulus clouds smoothly as overcast rises from clear to partly cloudy
                        float cloudPresence = smoothstep(0.0, 0.40, cloudWeatherFade);
                        baseCumulus *= cloudPresence;
                        // Mix in expanded coverage from both channels
                        float expandedCumulus = mix(baseCumulus, max(cloudData.x, cloudData.y) * cloudPresence, cloudWeatherFade);
                        // Overcast scales the optical density of the first layer of clouds
                        float firstLayerDensity = mix(0.75, 2.0, smoothstep(0.10, 0.85, cloudWeatherFade));
                        // As overcast approaches 1.0, an overcast cloud deck fills the sky
                        float overcastDeck = saturate((cloudWeatherFade - 0.70) * 3.5);
                        expandedCumulus = mix(expandedCumulus, max(expandedCumulus, 8.0 * cloudPresence), overcastDeck);
                        float cloudFinal = expandedCumulus * 0.125 * firstLayerDensity;
                    #endif
                #else
                    float cloudFinal = mix(baseCumulus, max(cloudData.x, cloudData.y), cloudWeatherFade) * 0.125;
                #endif
            #else
                float cloudFinal = baseCumulus * 0.125;
            #endif

            #ifdef FORCE_DISABLE_DAY_CYCLE
                vec3 cloudCelestialLight = lightCol;
            #else
                vec3 cloudCelestialLight = mix(moonCol, sunCol, dayCycleAdjust);
            #endif

            #ifndef FORCE_DISABLE_WEATHER
                cloudCelestialLight *= 1.0 - cloudWeatherFade;
                #ifdef STORY_MODE_CLOUDS
                    vec3 cloudSkyLight = mix(skyCol, skyCol * 0.85, cloudWeatherFade);
                #else
                    vec3 cloudSkyLight = mix(skyCol, skyCol * 0.35, cloudWeatherFade);
                #endif
            #else
                vec3 cloudSkyLight = skyCol;
            #endif

            vec3 lightDir = vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);
            cloudCelestialLight *= getCloudCelestialOcclusion(lightDir, cameraPosition, fragmentFrameTime);

            #ifdef EPILEPSY_SAFETY
                const float effectiveFlash = 0.0;
            #else
                float effectiveFlash = getLightningFlashIntensity();
            #endif
            vec3 flashLightCol = mix(vec3(1.0), LIGHTNING_COLOR, 0.25);
            vec3 cloudAmbient = toLinear(nightVision * 0.5 + AMBIENT_LIGHTING) + toLinear(flashLightCol) * effectiveFlash;
            #if WORLD_ID == 0
                if(effectiveFlash > 0.0) cloudCelestialLight = mix(cloudCelestialLight, toLinear(flashLightCol) * (effectiveFlash * 2.5), effectiveFlash);
            #endif
            #ifdef STORY_MODE_CLOUDS
                cloudAmbient += vec3(0.22 * cloudWeatherFade * dayCycleAdjust);
            #endif

            float cloudDensity = saturate(cloudFinal);
            vec3 cloudBaseCol = cloudAmbient + cloudCelestialLight + cloudSkyLight;

            #if WORLD_ID == 0 && defined CLOUD_LIGHTNING_GLOW && !defined EPILEPSY_SAFETY
                cloudBaseCol += getCloudInternalFlashGlow(nFeetPlayerPos, cloudDensity);
            #endif

            #if WORLD_ID == 0 && defined PALE_GARDEN_FOG
                float cloudFogAtten = isPaleGarden * min(1.0, PALE_GARDEN_FOG);
                float horizonFade = exp2(-max(0.0, nFeetPlayerPos.y) * 4.5);
                float totalCloudFog = saturate(cloudFogAtten * 0.85 + horizonFade * (0.35 * cloudFogAtten));
                cloudDensity *= 1.0 - totalCloudFog * 0.80;
                cloudBaseCol = mix(cloudBaseCol, getPaleGardenSkyColor(nFeetPlayerPos), isPaleGarden * 0.85);
            #endif

            vec3 celestialExcess = max(vec3(0.0), sceneCol - cloudSkyLight);
            vec3 occludedScene = min(sceneCol, cloudSkyLight) + celestialExcess * exp2(-cloudDensity * 8.0);
            return mix(occludedScene, cloudBaseCol, cloudDensity);
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
                float vxDepth = 1.0;
                if(vxOpaque > 0.0 && vxOpaque < 1.0) vxDepth = vxOpaque;
                if(vxTrans > 0.0 && vxTrans < vxDepth) vxDepth = vxTrans;
                if(vxDepth < 1.0){ depth = vxDepth; isLOD = true; }
            }
        #endif
    }

    vec3 getTranslucentViewPos(in bool isLOD, in vec3 screenPos){
        #ifdef DISTANT_HORIZONS
            return getViewPos(isLOD ? dhProjectionInverse : gbufferProjectionInverse, screenPos);
        #elif defined VOXY
            if(isLOD){
                #if defined USE_ZERO_ONE_DEPTH || (defined VOXY && VOXY >= 3) || (defined MC_VERSION && MC_VERSION >= 260300)
                    vec4 viewPosH = vxProjInv * vec4(screenPos.xy * 2.0 - 1.0, screenPos.z, 1.0);
                #else
                    vec4 viewPosH = vxProjInv * vec4(screenPos * 2.0 - 1.0, 1.0);
                #endif
                return viewPosH.xyz / viewPosH.w;
            } else {
                return getViewPos(gbufferProjectionInverse, screenPos);
            }
        #else
            return getViewPos(gbufferProjectionInverse, screenPos);
        #endif
    }

    #ifdef RAINBOW
        #if WORLD_ID == 0 && defined WORLD_LIGHT
            #ifndef FORCE_DISABLE_WEATHER
                vec3 getTranslucentRainbow(in vec3 nEyePlayerPos, in float viewDist, in bool isSky, in vec3 feetPlayerPos, in bool isWater){
                    if(isEyeInWater != 0) return vec3(0.0);
                    vec3 skyPos = mat3(shadowModelView) * nEyePlayerPos;
                    #ifndef FORCE_DISABLE_DAY_CYCLE
                        if(dayCycle < 1) skyPos.xz = -skyPos.xz;
                    #endif
                    return getRainbowRender(nEyePlayerPos, skyPos, viewDist, isSky, feetPlayerPos, false);
                }
            #endif
        #endif
    #endif

    vec3 shadeTranslucentSurface(
        in vec3 sceneCol, in vec3 screenPos, in vec3 viewPos, in vec3 nEyePlayerPos,
        in vec3 matRaw0, in ivec2 screenTexelCoord, in vec3 dither, in float viewDotInvSqrt,
        in float viewDist, in float fogFactor, in float borderFog, in bool isLOD
    ){
        #if defined SSGI
            const bool needsComplex = true;
        #else
            bool needsComplex = matRaw0.y >= 0.005;
        #endif

        if(needsComplex){
            vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;
            vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;
            bool isWater = abs(matRaw0.z - 0.35) < 0.05;
            sceneCol = complexShadingDeferred(sceneCol, screenPos, viewPos, mat3(gbufferModelView) * normal, albedo, dither, viewDotInvSqrt, matRaw0.x, matRaw0.y, isLOD, isWater);
        }

        vec3 fogSkyCol = applyPaleGardenFogColor(getSkyFogRender(nEyePlayerPos), nEyePlayerPos);
        #ifdef BORDER_FOG
            fogFactor = (fogFactor - 1.0) * borderFog + 1.0;
        #endif

        return ((fogSkyCol - sceneCol) * fogFactor + sceneCol) * getFogEffectFactor(viewDist);
    }

    vec3 applyAtmospherics(
        in vec3 sceneCol, in vec3 nEyePlayerPos, in vec3 feetPlayerPos, in vec3 dither,
        in float viewDist, in float fogFactor, in float borderFog, in float depth, in vec3 matRaw0
    ){
        #if defined WORLD_LIGHT || !defined FORCE_DISABLE_CLOUDS && CLOUD_TYPE == 2
            bool isSky = depth == 1.0;
            float feetPlayerDist = length(feetPlayerPos);
            vec3 nFeetPlayerPos = feetPlayerPos / max(0.0001, feetPlayerDist);
        #endif

        #if !defined FORCE_DISABLE_CLOUDS && CLOUD_TYPE == 2
            vec3 preCloudCol = sceneCol;
            sceneCol = renderTranslucentClouds(sceneCol, nFeetPlayerPos, feetPlayerDist, dither.x, isSky);
            if(matRaw0.z >= 0.99) sceneCol = mix(sceneCol, preCloudCol, matRaw0.x);
        #endif

        #ifdef WORLD_LIGHT
            if(VOLUMETRIC_LIGHTING_STRENGTH != 0 && isEyeInWater != 2) sceneCol += getVolumetricLight(nFeetPlayerPos, feetPlayerDist, fogFactor, borderFog, dither.x, isSky);
            #if defined GODRAYS
                sceneCol += getGodRays(texCoord, nEyePlayerPos, dither.x, depth);
            #endif
            #if defined RAINBOW && WORLD_ID == 0 && !defined FORCE_DISABLE_WEATHER
                sceneCol += getTranslucentRainbow(nEyePlayerPos, viewDist, isSky, feetPlayerPos, matRaw0.z > 0.0 && matRaw0.z < 1.0);
            #endif
        #endif

        return sceneCol;
    }

    void main(){
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        bool isLOD; float depth;
        getTranslucentSceneDepth(screenTexelCoord, depth, isLOD);
        vec3 screenPos = vec3(texCoord, depth);
        vec3 viewPos = getTranslucentViewPos(isLOD, screenPos);
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
        vec3 feetPlayerPos = eyePlayerPos + gbufferModelViewInverse[3].xyz;
        sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        #if ANTI_ALIASING >= 2
            vec3 dither = fract(getRng3(screenTexelCoord & 255) + frameFract);
        #else
            vec3 dither = getRng3(screenTexelCoord & 255);
        #endif

        float viewDot = lengthSquared(viewPos), viewDotInvSqrt = inversesqrt(viewDot);
        float viewDist = viewDot * viewDotInvSqrt;
        vec3 nEyePlayerPos = eyePlayerPos * viewDotInvSqrt;

        float fogFactor = getFogFactor(viewDist, nEyePlayerPos.y, feetPlayerPos.y + cameraPosition.y);

        #ifdef BORDER_FOG
            #ifdef VOXY
                float borderFog = exp2(-exp2(viewDist / max(float(vxRenderDistance), borderFar) * 21.0 - 18.0));
            #elif defined DISTANT_HORIZONS
                float borderFog = exp2(-exp2(viewDist / max(dhRenderDistance, borderFar) * 21.0 - 18.0));
            #else
                float borderFog = getBorderFog(viewDist);
            #endif
        #else
            const float borderFog = 0.0;
        #endif

        vec3 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xyz;
        if(matRaw0.z > 0 && matRaw0.z < 1)
            sceneColOut = shadeTranslucentSurface(sceneColOut, screenPos, viewPos, nEyePlayerPos, matRaw0, screenTexelCoord, dither, viewDotInvSqrt, viewDist, fogFactor, borderFog, isLOD);

        #if VOXY_DEBUG == 1
            if(isLOD && depth < 1.0) sceneColOut = mix(sceneColOut, vec3(1.0, 0.2, 0.2), 0.35);
        #endif

        // Apply darkness pulsing effect and clamp scene color
        sceneColOut = max(applyAtmospherics(sceneColOut * (1.0 - darknessLightFactor), nEyePlayerPos, feetPlayerPos, dither, viewDist, fogFactor, borderFog, depth, matRaw0), vec3(0));
    }
#endif
