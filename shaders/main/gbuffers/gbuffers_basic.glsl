/*
================================ /// Super Duper Vanilla v1.3.9 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2025 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.9 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec2 vertexLightMap;

    flat out vec4 vertexColor;

    #if WORLD_LIGHT == 1 && defined SHADOW_MAPPING
        out vec3 vertexShdPos;
    #endif

    #if defined SHADOW_MAPPING && WORLD_LIGHT == 1 || defined WORLD_CURVATURE
        uniform mat4 gbufferModelViewInverse;
    #endif

    #if WORLD_LIGHT == 1
        uniform mat4 shadowModelView;

        #ifdef SHADOW_MAPPING
            uniform mat4 shadowProjection;
        #endif
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif
    
    void main(){
        // Get vertex color
        vertexColor = gl_Color;

        // Lightmap fix for mods
        #if WORLD_SKYLIGHT == 1
            vertexLightMap = lightMapCoord(gl_MultiTexCoord1.xy);
        #else
            vertexLightMap = vec2(lightMapCoord(gl_MultiTexCoord1.x), WORLD_SKYLIGHT_I);
        #endif

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

        #if defined SHADOW_MAPPING && WORLD_LIGHT == 1 || defined WORLD_CURVATURE
            // Get vertex feet player position
            vec3 vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;
        #endif

        #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= lengthSquared(vertexFeetPlayerPos.xz) * worldCurvatureInv;

            // Convert back to vertex view position
            vertexViewPos = (vertexFeetPlayerPos - gbufferModelViewInverse[3].xyz) * mat3(gbufferModelViewInverse);
        #endif

        #if defined SHADOW_MAPPING && WORLD_LIGHT == 1
            // Calculate shadow pos in vertex
            vertexShdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexFeetPlayerPos + shadowModelView[3].xyz);
            vertexShdPos.z += shadowProjection[3].z;
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
    /* RENDERTARGETS: 4,3 */
    layout(location = 0) out vec3 sceneColOut; // colortex4
    layout(location = 1) out vec3 materialDataOut; // colortex3

    flat in vec2 vertexLightMap;

    flat in vec4 vertexColor;

    #if WORLD_LIGHT == 1 && defined SHADOW_MAPPING
        in vec3 vertexShdPos;
    #endif

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float lightningFlash;

    #if WORLD_WEATHER == 1
        uniform float rainStrength;
    #endif

    #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
        uniform int frameCounter;
    #endif

    #if WORLD_DAYCYCLE == 1
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #if WORLD_VANILLAFOG == 1
        uniform vec3 fogColor;
    #endif

    #if WORLD_SKYLIGHT == 1
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #else
        const float eyeBrightFact = WORLD_SKYLIGHT_I;
    #endif

    #if WORLD_LIGHT == 1
        uniform float shdFade;

        #ifdef SHADOW_MAPPING
            #ifdef SHADOW_FILTER
                #include "/lib/utility/noiseFunctions.glsl"
            #endif

            #include "/lib/lighting/shdDistort.glsl"
            #include "/lib/lighting/shdSample.glsl"
        #endif
    #endif

    #include "/lib/dimension/skyAdapter.glsl"
    #include "/lib/dimension/lightAdapter.glsl"

    #include "/lib/lighting/basicShadingForward.glsl"

    void main(){
        // Get albedo color
        vec4 albedo = vertexColor;

        // Alpha test, discard and return immediately
        if(albedo.a < ALPHA_THRESHOLD) { discard; return; }

        #if COLOR_MODE == 1
            albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            albedo.rgb = vec3(0);
        #endif

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

        // Apply simple shading
        sceneColOut = basicShadingForward(albedo.rgb, vertexLightMap);
    
        // Write material data
        materialDataOut = vec3(0);
    }
#endif