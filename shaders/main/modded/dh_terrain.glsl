/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out int blockId;

    flat out vec2 lmCoord;

    flat out vec3 vertexNormal;

    out float vertexViewDist;

    out vec3 vertexColor;
    out vec3 vertexFeetPlayerPos;
    out vec3 vertexWorldPos;

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif

    #ifdef WORLD_LIGHT
        uniform mat4 shadowModelView;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    void main(){
        // Get block id
        blockId = dhMaterialId;
        // Distant horizons terrain color is stored here
        vertexColor = gl_Color.rgb;

        // Distant horizons lightmap calculation
        #ifdef WORLD_CUSTOM_SKYLIGHT
            lmCoord = vec2(min((gl_MultiTexCoord1.x - 0.03125) * 1.06666667, 1.0), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = min((gl_MultiTexCoord1.xy - 0.03125) * 1.06666667, vec2(1));
        #endif

        // Get vertex normal
        vertexNormal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * fastNormalize(gl_Normal));

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Get vertex feet player position
        vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;
        // Output view distance
        vertexViewDist = length(vertexViewPos) + 8.0;

        // Get world position
        vertexWorldPos = vertexFeetPlayerPos + cameraPosition;

	    #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= lengthSquared(vertexFeetPlayerPos.xz) * worldCurvatureInv;

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
    layout(location = 0) out vec3 sceneColOut; // colortex4
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3

    flat in int blockId;

    flat in vec2 lmCoord;

    flat in vec3 vertexNormal;

    in float vertexViewDist;

    in vec3 vertexColor;
    in vec3 vertexFeetPlayerPos;
    in vec3 vertexWorldPos;

    uniform int isEyeInWater;

    uniform float far;

    uniform float nightVision;
    uniform float lightningFlash;

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
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

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/dataStructs.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #ifdef LAVA_NOISE
        uniform float fragmentFrameTime;

        #include "/lib/surface/lava.glsl"
    #endif

    #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
        uniform float isPrecipitationRain;

        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/modded/distantHorizons/complexShadingLOD.glsl"

    void main(){
        // Prevents overdraw
        if(far > vertexViewDist){ discard; return; }

        vec2 noiseUv = vertexWorldPos.zy * vertexNormal.x + vertexWorldPos.xz * vertexNormal.y + vertexWorldPos.xy * vertexNormal.z;
        vec2 noiseCol = texelFetch(noisetex, ivec2(noiseUv * 4.0) & 255, 0).xy;
        float dhNoise = (noiseCol.x + noiseCol.y) * 0.2 + 0.8;

        // Declare materials
	    dataPBR material;
        material.normal = vertexNormal;
        material.albedo = vec4(min(vertexColor * dhNoise, vec3(1)), 1);

        #if COLOR_MODE == 1
            material.albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            material.albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            material.albedo.rgb = vertexColor;
        #endif

        material.smoothness = 0.0; material.emissive = 0.0;
        material.metallic = 0.04; material.porosity = 0.0;
        material.ss = 0.0;
        
        // Currently unused
        material.parallaxShd = 1.0;
        material.ambient = 1.0;

        // If illuminated block
        if(blockId == DH_BLOCK_ILLUMINATED) material.emissive = 1.0;

        // If lava
        else if(blockId == DH_BLOCK_LAVA){
            #ifdef LAVA_NOISE
                // Lava tile size inverse
                const float lavaTileSizeInv = 1.0 / LAVA_TILE_SIZE;

                float lavaNoise = saturate(max(getLavaNoise(noiseUv * lavaTileSizeInv) * 3.0, sumOf(material.albedo.rgb)) - 1.0);
                material.albedo.rgb = floor(material.albedo.rgb * lavaNoise * LAVA_BRIGHTNESS * 32.0) * 0.03125;
            #else
                material.albedo.rgb = material.albedo.rgb * LAVA_BRIGHTNESS;
            #endif

            material.emissive = 1.0;
        }

        // If leaves
        else if(blockId == DH_BLOCK_LEAVES) material.ss = 0.5;

        // Convert to linear space
        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRONMENT_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != DH_BLOCK_LAVA && blockId != DH_BLOCK_ILLUMINATED) enviroPBR(material, vertexNormal);
        #endif

        // Apply simple shading
        sceneColOut = complexShadingLOD(material).rgb;

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0);
    }
#endif