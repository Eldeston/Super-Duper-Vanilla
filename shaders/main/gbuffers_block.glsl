/*
================================ /// Super Duper Vanilla v1.3.5 /// ================================

    Developed by Eldeston, presented by FlameRender (C) Studios.

    Copyright (C) 2023 Eldeston | FlameRender (C) Studios License


    By downloading this content you have agreed to the license and its terms of use.

================================ /// Super Duper Vanilla v1.3.5 /// ================================
*/

/// Buffer features: TAA jittering, complex shading, End portal, PBR, and world curvature

/// -------------------------------- /// Vertex Shader /// -------------------------------- ///

#ifdef VERTEX
    flat out vec2 lmCoord;

    flat out vec3 vertexColor;

    flat out mat3 TBN;

    out vec2 texCoord;

    out vec3 vertexFeetPlayerPos;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;

        out vec2 vTexCoord;
    #endif

    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
    #endif

    #if ANTI_ALIASING == 2
        uniform int frameMod8;

        uniform float pixelWidth;
        uniform float pixelHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    attribute vec4 at_tangent;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        attribute vec2 mc_midTexCoord;
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

        // Get vertex tangent
        vec3 vertexNormal = fastNormalize(gl_Normal);
        // Get vertex tangent
        vec3 vertexTangent = fastNormalize(at_tangent.xyz);

        // Get vertex view position
        vec3 vertexViewPos = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
        // Get vertex feet player position
        vertexFeetPlayerPos = mat3(gbufferModelViewInverse) * vertexViewPos + gbufferModelViewInverse[3].xyz;

        // Calculate TBN matrix
	    TBN = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * mat3(vertexTangent, cross(vertexTangent, vertexNormal) * sign(at_tangent.w), vertexNormal));

        #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * vec4(mc_midTexCoord, 0, 0)).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        #ifdef WORLD_CURVATURE
            // Apply curvature distortion
            vertexFeetPlayerPos.y -= dot(vertexFeetPlayerPos.xz, vertexFeetPlayerPos.xz) * worldCurvatureInv;

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
    /* RENDERTARGETS: 0,1,2,3 */
    layout(location = 0) out vec4 sceneColOut; // gcolor
    layout(location = 1) out vec3 normalDataOut; // colortex1
    layout(location = 2) out vec3 albedoDataOut; // colortex2
    layout(location = 3) out vec3 materialDataOut; // colortex3

    flat in vec2 lmCoord;

    flat in vec3 vertexColor;
    
    flat in mat3 TBN;

    in vec2 texCoord;

    in vec3 vertexFeetPlayerPos;

    #if defined NORMAL_GENERATION || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;

        in vec2 vTexCoord;
    #endif

    uniform int blockEntityId;

    uniform int isEyeInWater;

    uniform float nightVision;

    uniform float frameTimeCounter;

    uniform float pixelWidth;
    uniform float pixelHeight;

    uniform sampler2D tex;

    #ifdef IS_IRIS
        uniform float lightningFlash;
    #endif

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

        #ifdef SHADOW_MAPPING
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdMapping.glsl"
            #include "/lib/lighting/shdDistort.glsl"
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

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // End portal
        if(blockEntityId == 12000){
            // End star uv
            vec2 screenPos = gl_FragCoord.xy * vec2(pixelWidth, pixelHeight);
            float starSpeed = frameTimeCounter * 0.0078125;

            float endStarField = textureLod(tex, vec2(screenPos.y, screenPos.x + starSpeed) * 0.5, 0).r;
            endStarField += textureLod(tex, vec2(screenPos.x, screenPos.y + starSpeed), 0).r;
            endStarField += textureLod(tex, vec2(-screenPos.x, starSpeed - screenPos.y) * 2.0, 0).r;
            
            vec2 endStarCoord1 = vec2(screenPos.x - screenPos.y, screenPos.y + screenPos.x);
            endStarField += textureLod(tex, vec2(endStarCoord1.y, endStarCoord1.x + starSpeed) * 0.5, 0).r;
            endStarField += textureLod(tex, vec2(endStarCoord1.x, endStarCoord1.y + starSpeed), 0).r;
            endStarField += textureLod(tex, vec2(-endStarCoord1.x, starSpeed - endStarCoord1.y) * 2.0, 0).r;

            vec3 endPortalAlbedo = toLinear((endStarField + 0.0625) * (getRand3(ivec2(screenPos * 128.0) & 255) * 0.5 + 0.5) * vertexColor.rgb);

            sceneColOut = vec4(endPortalAlbedo * EMISSIVE_INTENSITY * EMISSIVE_INTENSITY, 1);

            // End portal fix
            normalDataOut = TBN[2];
            materialDataOut = vec3(0);

            return; // Return immediately, no need for lighting calculation
        }

	    // Declare materials
	    dataPBR material;
        getPBR(material, blockEntityId);

        // Convert to linear space
        material.albedo.rgb = toLinear(material.albedo.rgb);

        // Write to HDR scene color
        sceneColOut = vec4(complexShadingForward(material), material.albedo.a);

        // Write buffer datas
        normalDataOut = material.normal;
        albedoDataOut = material.albedo.rgb;
        materialDataOut = vec3(material.metallic, material.smoothness, 0);
    }
#endif