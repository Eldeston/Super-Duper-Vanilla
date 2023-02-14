/*
================================ /// Super Duper Vanilla v1.3.3 /// ================================

    Developed by Eldeston, presented by FlameRender (TM) Studios.

    Copyright (C) 2020 Eldeston | FlameRender (TM) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.3 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, PBR, lightning, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out float vertexAlpha;

    flat out vec3 vertexColor;

    flat out mat3 TBN;

    out vec2 lmCoord;
    out vec2 texCoord;

    out vec4 vertexPos;

    #ifdef PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;

        out vec2 vTexCoord;
    #endif

    uniform mat4 gbufferModelViewInverse;

    #if ANTI_ALIASING == 2
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    attribute vec4 at_tangent;

    #ifdef PARALLAX_OCCLUSION
        attribute vec2 mc_midTexCoord;
    #endif

    void main(){
        // Get vertex alpha
        vertexAlpha = gl_Color.a;
        // Get vertex color
        vertexColor = gl_Color.rgb;
        // Get buffer texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        // Get vertex tangent
        vec3 vertexTangent = fastNormalize(at_tangent.xyz);
        // Get vertex normal
        vec3 vertexNormal = fastNormalize(gl_Normal);

        // Get vertex position (feet player pos)
        vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        // Calculate TBN matrix
	    TBN = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * mat3(vertexTangent, cross(vertexTangent, vertexNormal), vertexNormal));

        // Lightmap fix for mods
        #ifdef WORLD_SKYLIGHT
            lmCoord = vec2(saturate(gl_MultiTexCoord1.x * 0.00416667), WORLD_SKYLIGHT);
        #else
            lmCoord = saturate(gl_MultiTexCoord1.xy * 0.00416667);
        #endif

        #ifdef PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0, 0)).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);

            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        gl_Position = ftransform();

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// -------------------------------- /// Fragment Shader /// -------------------------------- ///

#ifdef FRAGMENT
    flat in float vertexAlpha;

    flat in vec3 vertexColor;

    flat in mat3 TBN;

    in vec2 lmCoord;
    in vec2 texCoord;

    in vec4 vertexPos;

    #ifdef PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;

        in vec2 vTexCoord;
    #endif

    uniform int entityId;

    uniform int isEyeInWater;

    uniform float nightVision;
    uniform float lightningFlash;

    uniform vec4 entityColor;

    uniform sampler2D tex;

    // Texture coordinate derivatives
    vec2 dcdx = dFdx(texCoord);
    vec2 dcdy = dFdy(texCoord);

    #ifndef FORCE_DISABLE_WEATHER
        uniform float rainStrength;
    #endif

    #if ANTI_ALIASING >= 2
        uniform float frameTimeCounter;
    #endif

    #ifndef FORCE_DISABLE_DAY_CYCLE
        uniform float dayCycle;
        uniform float twilightPhase;
    #endif

    #ifdef WORLD_VANILLA_FOG_COLOR
        uniform vec3 fogColor;
    #endif

    #ifdef WORLD_SKYLIGHT
        const float eyeBrightFact = WORLD_SKYLIGHT;
    #else
        uniform float eyeSkylight;
        
        float eyeBrightFact = eyeSkylight;
    #endif

    #ifdef WORLD_LIGHT
        uniform float shdFade;

        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            uniform mat4 shadowProjection;

            #ifdef SHD_FILTER
                #include "/lib/utility/noiseFunctions.glsl"
            #endif

            #include "/lib/lighting/shdMapping.glsl"
            #include "/lib/lighting/shdDistort.glsl"
        #endif

        #include "/lib/lighting/GGX.glsl"
    #endif

    #include "/lib/PBR/structPBR.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/defaultPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Lightning fix, materials need to be specified due to glitching issues
        if(entityId == 10129){
            gl_FragData[0] = vec4(vec3(0.25, 0.5, 1) * EMISSIVE_INTENSITY, vertexAlpha); // gcolor
            gl_FragData[1] = vec4(0, 0, 0, 1); // colortex1
            gl_FragData[3] = vec4(0, 0, 0, 1); // colortex3
            return;
        }

        // Declare materials
	    structPBR material;
        getPBR(material, entityId);

        // Apply entity color tint
        material.albedo.rgb = mix(material.albedo.rgb, entityColor.rgb, entityColor.a);

        // Convert to linear space
        material.albedo.rgb = toLinear(material.albedo.rgb);

        vec4 sceneCol = complexShadingGbuffers(material);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(material.normal, 1); // colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); // colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); // colortex3
    }
#endif