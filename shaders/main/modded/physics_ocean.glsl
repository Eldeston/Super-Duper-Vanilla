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
    // Physics Mod varyings
    out float physics_localWaviness;

    out vec2 physics_localPosition;

    out vec2 lmCoord;
    out vec2 texCoord;
    out vec2 waterNoiseUv;

    out vec3 vertexColor;

    out vec3 vertexFeetPlayerPos;
    out vec3 vertexWorldPos;
    out vec3 vertexNormal;

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

    #ifdef WATER_ANIMATION
        uniform float vertexFrameTime;

        #include "/lib/vertex/waveWater.glsl"
    #endif

    #include "/lib/modded/physicsMod/physicsModVertex.glsl"

    void main(){
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Lightmap fix for mods
        #ifdef WORLD_CUSTOM_SKYLIGHT
            lmCoord = vec2(lightMapCoord(gl_MultiTexCoord1.x), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = lightMapCoord(gl_MultiTexCoord1.xy);
        #endif

        // Get vertex normal
        vertexNormal = fastNormalize(gl_Normal);

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Get vertex feet player position
        vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

        // Get world position
        vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

        // Get water noise uv position
        waterNoiseUv = vertexWorldPos.xz * waterTileSizeInv;

        // Physics mod vertex displacement
        // basic texture to determine how shallow/far away from the shore the water is
        physics_localWaviness = texelFetch(physics_waviness, ivec2(gl_Vertex.xz) - physics_textureOffset, 0).r;

        // pass this to the fragment shader to fetch the texture there for per fragment normals
        physics_localPosition = (gl_Vertex.xz - physics_waveOffset) * PHYSICS_XZ_SCALE * physics_oceanWaveHorizontalScale;

        // transform gl_Vertex (since it is the raw mesh, i.e. not transformed yet)
        vertexFeetPlayerPos.y += physics_waveHeight(physics_localPosition, physics_localWaviness);

        #ifdef WATER_ANIMATION
            vertexFeetPlayerPos = getWaterWave(vertexFeetPlayerPos, vertexWorldPos.xz, 11102, vertexFrameTime);
        #endif

        #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= dot(vertexFeetPlayerPos.xz, vertexFeetPlayerPos.xz) * worldCurvatureInv;
        #endif

        // Convert back to vertex view position
        vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;

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
    /* RENDERTARGETS: 0,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // colortex0
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3

    // Physics Mod varyings
    in float physics_localWaviness;

    in vec2 physics_localPosition;

    in vec2 lmCoord;
    in vec2 texCoord;
    in vec2 waterNoiseUv;

    in vec3 vertexColor;

    in vec3 vertexFeetPlayerPos;
    in vec3 vertexWorldPos;
    in vec3 vertexNormal;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float lightningFlash;

    uniform sampler2D gtexture;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
        uniform float frameFract;
    #endif

    #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
        uniform float near;

        uniform sampler2D depthtex1;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #ifdef WORLD_VANILLA_FOG_COLOR
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

    #include "/lib/utility/noiseFunctions.glsl"

    #if defined WATER_NORMAL || defined WATER_NOISE
        uniform float fragmentFrameTime;

        #include "/lib/surface/water.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    #include "/lib/modded/physicsMod/physicsModFragment.glsl"

    void main(){
	    // Declare materials
	    dataPBR material;
        material.albedo = textureGrad(gtexture, texCoord, dFdx(texCoord), dFdy(texCoord));
        material.albedo.rgb *= vertexColor;
        material.normal = vertexNormal;

        #if COLOR_MODE == 0
            material.albedo.rgb *= vertexColor;
        #elif COLOR_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            material.albedo.rgb = vertexColor;
        #endif

        material.smoothness = 0.96; material.emissive = 0.0;
        material.metallic = 0.04; material.porosity = 0.0;
        material.ss = 0.0; material.parallaxShd = 1.0;
        material.ambient = 1.0;

        float waterNoise = WATER_BRIGHTNESS;

        // Physics mod water normal calculation
        WavePixelData wave = physics_wavePixel(physics_localPosition, physics_localWaviness);

        // Underwater normal fix
        material.normal = wave.normal;

        // Apply physics foam
        float physicsFoam = fastSqrt(wave.foam);
        material.albedo = min(vec4(1), material.albedo + physicsFoam);

        waterNoise *= (getCellNoise(waterNoiseUv) + physicsFoam) * 0.5;

        #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
            // Water color and foam. Fast depth linearization by DrDesten
            // Not great, but plausible for most scenarios
            float waterDepth = near / (1.0 - gl_FragCoord.z) - near / (1.0 - texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).x);
        #endif

        #ifdef WATER_STYLIZE_ABSORPTION
            if(isEyeInWater == 0){
                float depthBrightness = exp2(waterDepth * 0.25);
                material.albedo.rgb = material.albedo.rgb * (waterNoise * (1.0 - depthBrightness) + depthBrightness);
                material.albedo.a = fastSqrt(material.albedo.a) * (1.0 - depthBrightness);
            }
            else material.albedo.rgb *= waterNoise;
        #else
            material.albedo.rgb *= waterNoise;
        #endif

        #ifdef WATER_FOAM
            material.albedo = min(vec4(1), material.albedo + exp2((waterDepth + 0.0625) * 8.0));
        #endif

        material.albedo.rgb = toLinear(material.albedo.rgb);

        // Write to HDR scene color
        sceneColOut = complexShadingForward(material);

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0.5);
    }
#endif