/*
================================ /// Super Duper Vanilla v1.3.6 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.6 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec2 lmCoord;

    flat out vec3 vertexColor;

    out vec2 texCoord;

    #if defined WORLD_LIGHT && defined SHADOW_MAPPING
        out vec3 vertexShdPos;
    #endif

    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif

    #ifdef WORLD_LIGHT
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
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Lightmap fix for mods
        #ifdef WORLD_CUSTOM_SKYLIGHT
            lmCoord = vec2(min(gl_MultiTexCoord1.x * 0.00416667, 1.0), WORLD_CUSTOM_SKYLIGHT);
        #else
            lmCoord = min(gl_MultiTexCoord1.xy * 0.00416667, vec2(1));
        #endif

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;

        #if defined SHADOW_MAPPING && defined WORLD_LIGHT || defined WORLD_CURVATURE
            // Get vertex feet player position
            vec3 vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;
        #endif

	    #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= lengthSquared(vertexFeetPlayerPos.xz) * worldCurvatureInv;

            // Convert back to vertex view position
            vertexViewPos = mat3(gbufferModelView) * vertexFeetPlayerPos + gbufferModelView[3].xyz;
        #endif

        #if defined SHADOW_MAPPING && defined WORLD_LIGHT
            // Calculate shadow pos in vertex
            vertexShdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexFeetPlayerPos + shadowModelView[3].xyz);
			vertexShdPos.z += shadowProjection[3].z;
            vertexShdPos.z = vertexShdPos.z * 0.1 + 0.5;
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
    /* RENDERTARGETS: 0,3 */
    layout(location = 0) out vec4 sceneColOut; // gcolor
    layout(location = 1) out vec3 materialDataOut; // colortex3

    flat in vec2 lmCoord;

    flat in vec3 vertexColor;

    in vec2 texCoord;

    #if defined WORLD_LIGHT && defined SHADOW_MAPPING
        in vec3 vertexShdPos;
    #endif

    uniform int isEyeInWater;

    uniform float nightVision;

    uniform ivec2 atlasSize;

    uniform sampler2D tex;

    #ifdef MC_RENDER_STAGE_WORLD_BORDER
        uniform int renderStage;
    #endif

    #ifdef IS_IRIS
        uniform float lightningFlash;
    #endif

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if defined SHADOW_FILTER && ANTI_ALIASING >= 2
        uniform float frameFract;
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

        #ifdef SHADOW_MAPPING
            #ifdef SHADOW_FILTER
                #include "/lib/utility/noiseFunctions.glsl"
            #endif

            #include "/lib/lighting/shdMapping.glsl"
        #endif
    #endif

    #include "/lib/lighting/basicShadingForward.glsl"

    void main(){
        // Get albedo
        vec4 albedo = textureLod(tex, texCoord, 0);

        // Alpha test, discard and return immediately
        if(albedo.a < ALPHA_THRESHOLD){ discard; return; }

        // World border fix + emissives
        if(renderStage == MC_RENDER_STAGE_WORLD_BORDER){
            const vec3 borderCol = vec3(0.125, 0.25, 0.5) * EMISSIVE_INTENSITY;
            sceneColOut = vec4(borderCol, albedo.a);
            return; // Return immediately, no need for lighting calculation
        }

        // Particle emissives
        if((vertexColor.r * 0.5 > vertexColor.g + vertexColor.b || (vertexColor.r + vertexColor.b > vertexColor.g * 2.0 && abs(vertexColor.r - vertexColor.b) < 0.2) || ((albedo.r + albedo.g + albedo.b > 1.6 || (vertexColor.r != vertexColor.g && vertexColor.g != vertexColor.b)) && lmCoord.x == 1)) && atlasSize.x <= 1024 && atlasSize.x > 0){
            sceneColOut = vec4(toLinear(albedo.rgb * vertexColor) * EMISSIVE_INTENSITY, albedo.a);
            return; // Return immediately, no need for lighting calculation
        }

        #if COLOR_MODE == 0
            albedo.rgb *= vertexColor;
        #elif COLOR_MODE == 1
            albedo.rgb = vec3(1);
        #elif COLOR_MODE == 2
            albedo.rgb = vec3(0);
        #elif COLOR_MODE == 3
            albedo.rgb = vertexColor;
        #endif

        // Convert to linear space
        albedo.rgb = toLinear(albedo.rgb);

        // Apply simple shading
        sceneColOut = vec4(basicShadingForward(albedo), albedo.a);

        // Write material data
        materialDataOut = vec3(0);
    }
#endif