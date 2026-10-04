/*
================================ /// Super Duper Vanilla v1.3.8 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.8 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, animation, water noise, PBR, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out int blockId;
    flat out float midBlockY;

    out vec2 lmCoord;
    out vec2 texCoord;
    out vec2 waterNoiseUv;

    out vec4 vertexColor;
    out vec3 vertexFeetPlayerPos;
    out vec3 vertexWorldPos;

    out mat3 TBN;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;

        out vec2 vTexCoord;
    #endif

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelViewInverse;

    #if defined WATER_ANIMATION || defined WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif
    
    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    attribute vec3 at_midBlock;

    #ifdef WATER_ANIMATION
        uniform float vertexFrameTime;

        #include "/lib/vertex/waveWater.glsl"
    #endif

    attribute vec3 mc_Entity;

    attribute vec4 at_tangent;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        attribute vec2 mc_midTexCoord;
    #endif

    void main(){
        // Get block id
        blockId = int(mc_Entity.x);
        midBlockY = at_midBlock.y * 0.015625;
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color;

        // Lightmap fix for mods
        #ifdef WORLD_CUSTOM_SKYLIGHT
            lmCoord = vec2(lightMapCoord(gl_MultiTexCoord1.x), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = lightMapCoord(gl_MultiTexCoord1.xy);
        #endif

        // Get vertex normal
        vec3 vertexNormal = fastNormalize(gl_Normal);
        // Get vertex tangent
        vec3 vertexTangent = fastNormalize(at_tangent.xyz);

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Get vertex feet player position
        vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

        // Get world position
        vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

        // Get water noise uv position
        waterNoiseUv = vertexWorldPos.xz * waterTileSizeInv;

        // Calculate TBN matrix
	    TBN = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * mat3(vertexTangent, cross(vertexTangent, vertexNormal) * sign(at_tangent.w), vertexNormal));

        #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0, 0)).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        #ifdef WATER_ANIMATION
            vertexFeetPlayerPos = getWaterWave(vertexFeetPlayerPos, vertexWorldPos.xz, at_midBlock.y * 0.015625, mc_Entity.x, lmCoord.y, vertexFrameTime);
        #endif

        #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= dot(vertexFeetPlayerPos.xz, vertexFeetPlayerPos.xz) * worldCurvatureInv;
        #endif

        #if defined WATER_ANIMATION || defined WORLD_CURVATURE
            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;
        #endif

        // Convert to clip position and output as final position
        // gl_Position = gl_ProjectionMatrix * vertexViewPos;
        gl_Position.xyz = getMatScale(mat3(gl_ProjectionMatrix)) * vertexViewPos;
        gl_Position.z += gl_ProjectionMatrix[3].z;

        gl_Position.w = -vertexViewPos.z;

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    /* RENDERTARGETS: 4,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // colortex4
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3

    flat in int blockId;
    flat in float midBlockY;

    in vec2 lmCoord;
    in vec2 texCoord;
    in vec2 waterNoiseUv;

    in vec4 vertexColor;
    in vec3 vertexFeetPlayerPos;
    in vec3 vertexWorldPos;

    in mat3 TBN;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;

        in vec2 vTexCoord;
    #endif

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float lightningFlash;

    uniform float near;

    uniform sampler2D depthtex1;
    uniform sampler2D gtexture;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
        uniform float weatherFade;
        #if WORLD_ID == 0
            #ifndef THUNDER_STRENGTH_DECLARED
                #define THUNDER_STRENGTH_DECLARED
                uniform float thunderStrength;
            #endif
            #ifdef DYNAMIC_WEATHER
                #ifndef DYNAMIC_THUNDER_DECLARED
                    #define DYNAMIC_THUNDER_DECLARED
                    uniform float dynamicThunderStrength;
                #endif
            #endif
        #endif
    #endif

    #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
        uniform float frameFract;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #if defined WORLD_VANILLA_FOG_COLOR || !defined FORCE_DISABLE_WEATHER
        uniform vec3 fogColor;
    #endif

    #ifdef WORLD_CUSTOM_SKYLIGHT
        const float eyeBrightFact = WORLD_CUSTOM_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        uniform mat4 shadowModelView;

        #ifdef SHADOW_MAPPING
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdMapping.glsl"
        #endif

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/dataStructs.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/integratedPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #include "/lib/utility/noiseFunctions.glsl"

    #if defined WATER_NORMAL || defined WATER_NOISE
        uniform float fragmentFrameTime;

        #include "/lib/surface/water.glsl"
    #endif

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        uniform float isPrecipitationRain;

        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    void applyWaterSurface(inout dataPBR material, in float blockDepth, in float verticalDepth, in float waveAmp, in float edgeBrightness){
        float waterNoise = WATER_BRIGHTNESS;

        #if WORLD_ID == 0 && !defined FORCE_DISABLE_WEATHER
            #ifdef DYNAMIC_WEATHER
                float stormFactor = dynamicThunderStrength;
            #else
                float stormFactor = thunderStrength;
            #endif
            float windExposure = smoothstep(0.70, 0.98, lmCoord.y);
            float waterStormWind = stormFactor * windExposure;
        #else
            const float waterStormWind = 0.0;
        #endif

        #if defined WATER_NORMAL
            vec4 waterData = H2NWater(waterNoiseUv, waterStormWind).xzyw;
            waterData.xz *= waveAmp;
            material.normal = fastNormalize(waterData.yxz * TBN[2].x + waterData.xyz * TBN[2].y + waterData.xzy * TBN[2].z);

            #ifdef WATER_NOISE
                float causticNoise = squared(0.128 + waterData.w * 0.5);
                float causticMask = (midBlockY > 0.0) ? 0.0 : 1.0;
                waterNoise *= mix(1.0, causticNoise, causticMask);
            #endif
        #elif defined WATER_NOISE
            float currentSpeed = CURRENT_SPEED * 0.0625 * (1.0 + waterStormWind * 1.6);
            float waterData = getCellNoise(waterNoiseUv, fragmentFrameTime * currentSpeed);
            float causticNoise = squared(0.128 + waterData * 0.5);
            float causticMask = (midBlockY > 0.0) ? 0.0 : 1.0;

            waterNoise *= mix(1.0, causticNoise, causticMask);
        #endif

        #if WATER_STYLE == 1
            // Vanilla style: preserve the iconic animated water texture and authentic vanilla opacity
            #ifdef WATER_STYLIZE_ABSORPTION
                float depthBrightness = exp2(blockDepth * 0.20);
                material.albedo.rgb *= mix(vec3(0.72, 0.82, 0.96), vec3(1.0), depthBrightness);
                float targetAlpha = mix(0.62, 0.76, 1.0 - depthBrightness);
            #else
                const float targetAlpha = 0.68;
            #endif

            #ifdef WATER_DEPTH_WAVES
                float shoreFade = smoothstep(0.0, 0.05, verticalDepth);
                material.albedo.a = mix(0.38, targetAlpha, shoreFade);
            #else
                material.albedo.a = targetAlpha;
            #endif
        #else
            // Realistic style: high transparency and clarity
            #ifdef WATER_STYLIZE_ABSORPTION
                if(isEyeInWater == 0){
                    float depthBrightness = exp2(blockDepth * 0.25);
                    material.albedo.rgb = material.albedo.rgb * (waterNoise * (1.0 - depthBrightness) + depthBrightness);

                    #ifdef WATER_DEPTH_WAVES
                        float absorptionFade = mix(1.0, 1.0 - depthBrightness, smoothstep(0.02, 0.15, verticalDepth));
                    #else
                        float absorptionFade = 1.0 - depthBrightness;
                    #endif
                    material.albedo.a = fastSqrt(material.albedo.a) * absorptionFade;
                }
                else material.albedo.rgb *= waterNoise;
            #else
                material.albedo.rgb *= waterNoise;
            #endif
        #endif

        #ifdef WATER_FOAM
            #ifdef WATER_DEPTH_WAVES
                if(midBlockY <= 0.0 && verticalDepth > 0.001){
                    material.albedo = min(vec4(1.0), material.albedo + edgeBrightness);
                }
            #else
                material.albedo = min(vec4(1.0), material.albedo + edgeBrightness);
            #endif
        #endif
    }

    void main(){
	    // Declare materials
	    dataPBR material;
        getPBR(material, blockId);

        // Apply vertex alpha for modded translucent rendering (e.g. Litematica ghost blocks)
        if(blockId != 11102 && blockId != 12100) material.albedo.a *= vertexColor.a;
        if(material.albedo.a <= 0.001){ discard; return; }

        if(blockId == 11102 || blockId == 12100){
            // Fast depth linearization by DrDesten
            float rawSolidDepth = texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).x;
            float blockDepth = (rawSolidDepth >= 0.999999) ? -100.0 : near / (1.0 - gl_FragCoord.z) - near / (1.0 - rawSolidDepth);

            // Water depth in blocks along the vertical axis (invariant to viewing angle)
            #ifdef WATER_DEPTH_WAVES
                float cosTheta = clamp(abs(dot(fastNormalize(-vertexFeetPlayerPos), TBN[2])), 0.15, 1.0);
                float verticalDepth = (rawSolidDepth >= 0.999999 || isEyeInWater != 0 || TBN[2].y < 0.5) ? 10.0 : max(0.0, -blockDepth) * cosTheta;
                float waveAmp = (midBlockY > 0.0) ? 0.0 : smoothstep(0.02, 1.8, verticalDepth);
            #else
                const float waveAmp = 1.0;
                float verticalDepth = max(0.0, -blockDepth);
            #endif

            // Get the depth outline for the end portal
            float edgeBrightness = exp2((blockDepth + 0.0625) * 8.0);

            // Water
            if(blockId == 11102){
                applyWaterSurface(material, blockDepth, verticalDepth, waveAmp, edgeBrightness);
            }

            // Nether portal
            else material.albedo.rgb = min(vec3(1), material.albedo.rgb * (0.5 + edgeBrightness * 2.0));
        }

        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != 11102) enviroPBR(material, TBN[2]);
        #endif

        // Write to HDR scene color
        sceneColOut = vec4(complexShadingForward(material), material.albedo.a);

        #if VOXY_DEBUG == 1
            sceneColOut.rgb = mix(sceneColOut.rgb, vec3(0.2, 0.8, 1.0), 0.15);
        #elif VOXY_DEBUG == 2
            sceneColOut.rgb = vec3(lmCoord.x, lmCoord.y, 0.0);
        #elif VOXY_DEBUG == 3
            sceneColOut.rgb = material.normal * 0.5 + 0.5;
        #endif

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, (blockId == 11102) ? 0.35 : 0.5);
    }
#endif