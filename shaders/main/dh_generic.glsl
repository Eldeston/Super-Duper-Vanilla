/*
================================ /// Super Duper Vanilla v1.3.7 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.7 /// ================================
*/

/// Buffer features: TAA jittering, simple shading, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out float vertexNLZ;

        #ifdef SHADOW_MAPPING
            flat out float vertexNLX;
            flat out float vertexNLY;

            out vec3 vertexShdPos;
        #endif
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

        #ifdef WORLD_LIGHT
            vec3 vertexNormal = mat3(gbufferModelViewInverse) * fastNormalize(gl_NormalMatrix * gl_Normal);

            vertexNLZ = dot(vertexNormal, vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z));

            #ifdef SHADOW_MAPPING
                // Since we already have vertexNLZ, we just need NLX and NLY to complete the shadow normal
                vertexNLX = dot(vertexNormal, vec3(shadowModelView[0].x, shadowModelView[1].x, shadowModelView[2].x));
                vertexNLY = dot(vertexNormal, vec3(shadowModelView[0].y, shadowModelView[1].y, shadowModelView[2].y));

                // Calculate shadow pos in vertex
                vertexShdPos = vec3(shadowProjection[0].x, shadowProjection[1].y, shadowProjection[2].z) * (mat3(shadowModelView) * vertexFeetPlayerPos + shadowModelView[3].xyz);
                vertexShdPos.z += shadowProjection[3].z;
                vertexShdPos.z = vertexShdPos.z * 0.1 + 0.5;
            #endif
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
    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 sceneColOut; // gcolor

    #ifdef WORLD_LIGHT
        flat in float vertexNLZ;

        #ifdef SHADOW_MAPPING
            flat in float vertexNLX;
            flat in float vertexNLY;

            in vec3 vertexShdPos;
        #endif
    #endif

    uniform int isEyeInWater;

    uniform float nightVision;

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
        // Apply basic shading
        sceneColOut = vec4(basicShadingForward(vec3(1)), 1);
    }
#endif