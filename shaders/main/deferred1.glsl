/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: Solid complex shading

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
        uniform float rainStrength;
        uniform float weatherFade;
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

        #if WORLD_ID == 0
            uniform float lightningFlash;
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
                float celestialVis = 1.0 - effectiveWeatherFade;
            #else
                const float celestialVis = 1.0;
            #endif
            #ifdef FORCE_DISABLE_DAY_CYCLE
                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK0 * celestialVis;
                lightCol = toLinear(sRGBLightCol);
            #else
                sRGBSunCol = SUN_COLOR_BASE * celestialVis;
                sunCol = toLinear(SUN_COL_DATA_BLOCK) * celestialVis;
                sRGBMoonCol = MOON_COLOR_BASE * celestialVis;
                moonCol = toLinear(MOON_COL_DATA_BLOCK) * celestialVis;
                sRGBLightCol = LIGHT_COLOR_DATA_BLOCK1(sRGBSunCol, sRGBMoonCol);
                lightCol = toLinear(sRGBLightCol);
            #endif
            #if WORLD_ID == 0 && !defined EPILEPSY_SAFETY
                if(lightningFlash > 0.0){
                    vec3 nearWhiteLight = mix(vec3(1.0), LIGHTNING_COLOR, 0.20) * (lightningFlash * 2.5);
                    sRGBSunCol = mix(sRGBSunCol, nearWhiteLight, lightningFlash);
                    sunCol = toLinear(sRGBSunCol);
                    sRGBMoonCol = mix(sRGBMoonCol, nearWhiteLight, lightningFlash);
                    moonCol = toLinear(sRGBMoonCol);
                    sRGBLightCol = mix(sRGBLightCol, nearWhiteLight, lightningFlash);
                    lightCol = toLinear(sRGBLightCol);
                }
            #endif
        #endif

        gl_Position = vec4(gl_Vertex.xy * 2.0 - 1.0, 0, 1);
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4 */
    layout(location = 0) out vec3 sceneColOut; // colortex4

    // Sky silhoutte fix
    const vec4 gcolorClearColor = vec4(0, 0, 0, 1);

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
    uniform float fogStart;
    uniform float fogEnd;

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

    #ifdef WORLD_LIGHT
        uniform float shdFade;
    #endif

    #if ANTI_ALIASING >= 2
        uniform float frameFract;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
        uniform float weatherFade;
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

    #if CLOUD_TYPE != 0 && !defined FORCE_DISABLE_CLOUDS
        uniform sampler2D colortex0;
    #endif

    #ifdef DISTANT_HORIZONS
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

    #ifdef SSAO
        float getSSAOBoxBlur(in ivec2 screenTexelCoord){
            ivec2 topRightCorner = screenTexelCoord + 1;
            ivec2 bottomLeftCorner = screenTexelCoord - 1;

            float sample0 = texelFetch(colortex2, topRightCorner, 0).a;
            float sample1 = texelFetch(colortex2, bottomLeftCorner, 0).a;
            float sample2 = texelFetch(colortex2, ivec2(topRightCorner.x, bottomLeftCorner.y), 0).a;
            float sample3 = texelFetch(colortex2, ivec2(bottomLeftCorner.x, topRightCorner.y), 0).a;

            return sample0 + sample1 + sample2 + sample3;
        }
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #include "/lib/utility/depthTex.glsl"

    #if OUTLINES != 0
        #if OUTLINES == 1
            uniform float near;
        #endif

        #include "/lib/post/outline.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/atmospherics/skyRender.glsl"
    #include "/lib/atmospherics/fogRender.glsl"
    
    #include "/lib/rayTracing/rayTracer.glsl"

    #include "/lib/lighting/complexShadingDeferred.glsl"

    vec3 getDeferredViewPos(in bool isLOD, in vec3 screenPos){
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

    #ifdef BORDER_FOG
        float getDeferredBorderFog(in float viewDist, in float fogFactor){
            #ifdef VOXY
                float effectiveBorderFar = max(float(vxRenderDistance), borderFar);
                return (fogFactor - 1.0) * exp2(-exp2(viewDist / effectiveBorderFar * 21.0 - 18.0)) + 1.0;
            #elif defined DISTANT_HORIZONS
                float effectiveBorderFar = max(dhRenderDistance, borderFar);
                return (fogFactor - 1.0) * exp2(-exp2(viewDist / effectiveBorderFar * 21.0 - 18.0)) + 1.0;
            #else
                return (fogFactor - 1.0) * getBorderFog(viewDist) + 1.0;
            #endif
        }
    #endif

    void getDeferredSceneDepth(in ivec2 screenTexelCoord, out float depth, out bool isLOD){
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
                if(vxDepth < 1.0){
                    depth = vxDepth;
                    isLOD = true;
                }
            }
        #endif
    }

vec3 applyDeferredSkyEffects(in vec3 sceneCol, in vec3 nEyePlayerPos, in vec3 skyPos, in vec3 currSkyCol){
    #if WORLD_ID == 1 && defined END_BOSS_FOG
        if(isEyeInWater == 0 && END_BOSS_FOG > 0.0 && fogEnd <= 100.0 && (fogStart / max(fogEnd, 0.001)) < 0.60 && effectFactor < 0.01){
            float horizonBossFog = exp2(-max(0.0, nEyePlayerPos.y) * (14.0 / max(END_BOSS_FOG, 0.5))) * (0.90 * min(1.0, END_BOSS_FOG));
            vec3 bossSkyFogCol = getSkyFogRender(nEyePlayerPos, skyPos, currSkyCol);
            sceneCol = mix(sceneCol, bossSkyFogCol, horizonBossFog);
        }
    #endif
    #if WORLD_ID == 0 && defined PALE_GARDEN_FOG
        if(isEyeInWater == 0 && PALE_GARDEN_FOG > 0.0 && isPaleGarden > 0.001 && effectFactor < 0.01){
            vec3 paleSkyCol = getPaleGardenSkyColor(nEyePlayerPos);
            float skyMistFade = saturate(exp2(-max(0.0, nEyePlayerPos.y) * 1.6) * 0.28 + 0.72);
            sceneCol = mix(sceneCol, paleSkyCol, isPaleGarden * skyMistFade * min(1.0, PALE_GARDEN_FOG));
        }
    #endif
    return sceneCol;
}

    void main(){
        // Screen texel coordinates
        ivec2 screenTexelCoord = ivec2(gl_FragCoord.xy);

        bool isLOD;
        float depth;
        getDeferredSceneDepth(screenTexelCoord, depth, isLOD);

        // Get screen pos
        vec3 screenPos = vec3(texCoord, depth);

        // Get sky mask
        bool skyMask = screenPos.z == 1.0;

        // Jitter the sky only
        #if ANTI_ALIASING == 2
            if(skyMask) screenPos.xy += jitterPos(-0.5);
        #endif

        vec3 viewPos = getDeferredViewPos(isLOD, screenPos);

        // Get eye player pos
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

        // Get view distance
        float viewDot = lengthSquared(viewPos);
	    float viewDotInvSqrt = inversesqrt(viewDot);

        // Get normalized eyePlayerPos
        vec3 nEyePlayerPos = eyePlayerPos * viewDotInvSqrt;

        // Get scene color
        sceneColOut = texelFetch(colortex4, screenTexelCoord, 0).rgb;

        // Get sky pos by shadow model view (or fixed black hole matrix in the End)
        #if WORLD_ID == 1
            const mat3 blackHoleSkyMatrix = mat3(
                1.0,  0.0,         0.0,
                0.0, -0.7431448,   0.6691306,
                0.0, -0.6691306,  -0.7431448
            );
            vec3 skyPos = blackHoleSkyMatrix * nEyePlayerPos;
        #else
            vec3 skyPos = mat3(shadowModelView) * nEyePlayerPos;
        #endif

        #if defined WORLD_LIGHT && !defined FORCE_DISABLE_DAY_CYCLE
            // Flip if the sun has gone below the horizon
            if(dayCycle < 1) skyPos.xz = -skyPos.xz;
        #endif

        // Get basic sky simple color
        vec3 currSkyCol = getSkyBasic(nEyePlayerPos.y, skyPos.z);

        // If sky, do full sky render and return immediately
        if(skyMask){
            // Calculate and output sky render
            sceneColOut = getFullSkyRender(nEyePlayerPos, skyPos, currSkyCol + sceneColOut) * exp2(-borderFar * effectFactor);
            sceneColOut = applyDeferredSkyEffects(sceneColOut, nEyePlayerPos, skyPos, currSkyCol);
            // Exit function immediately
            return;
        }

        #if ANTI_ALIASING >= 2
            vec3 dither = fract(getRng3(screenTexelCoord & 255) + frameFract);
        #else
            vec3 dither = getRng3(screenTexelCoord & 255);
        #endif

        // Declare and get materials
        vec2 matRaw0 = texelFetch(colortex3, screenTexelCoord, 0).xy;

        #if defined SSGI
            const bool needsComplex = true;
        #else
            bool needsComplex = matRaw0.y >= 0.005;
        #endif

        if(needsComplex){
            vec3 albedo = texelFetch(colortex2, screenTexelCoord, 0).rgb;
            vec3 normal = texelFetch(colortex1, screenTexelCoord, 0).xyz;

            // Apply deferred shading
            sceneColOut = complexShadingDeferred(sceneColOut, screenPos, viewPos, mat3(gbufferModelView) * normal, albedo, dither, viewDotInvSqrt, matRaw0.x, matRaw0.y, isLOD);
        }

        #if OUTLINES != 0
            // Outline calculation
            sceneColOut *= 1.0 + getOutline(screenTexelCoord, screenPos.z) * OUTLINE_BRIGHTNESS;
        #endif

        #ifdef SSAO
            // Apply ambient occlusion with simple blur
            sceneColOut *= getSSAOBoxBlur(screenTexelCoord);
        #endif

        float viewDist = viewDot * viewDotInvSqrt;

        // Get basic sky fog color
        vec3 fogSkyCol = applyPaleGardenFogColor(getSkyFogRender(nEyePlayerPos, skyPos, currSkyCol), nEyePlayerPos);
        // Get fog factor
        float fogFactor = getFogFactor(viewDist, nEyePlayerPos.y, eyePlayerPos.y + gbufferModelViewInverse[3].y + cameraPosition.y);

        // Border fog
        #ifdef BORDER_FOG
            fogFactor = getDeferredBorderFog(viewDist, fogFactor);
        #endif

        // Apply fog and darkness fog
        sceneColOut = ((fogSkyCol - sceneColOut) * fogFactor + sceneColOut) * getFogEffectFactor(viewDist);

        #if VOXY_DEBUG == 1
            if(realSky && !skyMask) sceneColOut = mix(sceneColOut, vec3(1.0, 0.2, 0.2), 0.35);
        #endif

        // Clamp scene color to prevent NaNs during post processing
        sceneColOut = max(sceneColOut, vec3(0));
    }
#endif