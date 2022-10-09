// Get frame time
uniform float frameTimeCounter;

/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out vec3 shdLightView;

        #ifdef SHD_ENABLE
            out vec3 shdPos;

            out float distortFactor;
        #endif
    #endif

    flat out mat3 TBN;
    
    flat out int blockId;

    flat out vec3 vertexColor;

    out float vertexAO;

    out vec2 lmCoord;
    out vec2 texCoord;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat out vec2 vTexCoordScale;
        flat out vec2 vTexCoordPos;
        out vec2 vTexCoord;
    #endif

    out vec3 worldPos;

    out vec4 vertexPos;

    // View matrix uniforms
    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;

            #include "/lib/lighting/shdDistort.glsl"
        #endif
    #endif

    // Position uniforms
    uniform vec3 cameraPosition;

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #if TIMELAPSE_MODE == 2
        uniform float animationFrameTime;

        float newFrameTimeCounter = animationFrameTime;
    #else
        float newFrameTimeCounter = frameTimeCounter;
    #endif

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION || defined ANIMATE
        attribute vec4 mc_midTexCoord;
    #endif

    #include "/lib/vertex/vertexAnimations.glsl"

    void main(){
        // Get block id
        blockId = int(mc_Entity.x);
        // Get vertex AO
        vertexAO = gl_Color.a;
        // Get texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Get vertex color
        vertexColor = gl_Color.rgb;

        // Get vertex tangent
        vec3 vertexTangent = normalize(at_tangent.xyz);
        // Get vertex normal
        vec3 vertexNormal = normalize(gl_Normal);

        // Get vertex position (view player pos)
        vertexPos = gl_ModelViewMatrix * gl_Vertex;
        // Get feet player pos
        vec4 feetPlayerPos = gbufferModelViewInverse * vertexPos;
        // Get world position
        worldPos = feetPlayerPos.xyz + cameraPosition;

        // Calculate TBN matrix
	    TBN = gl_NormalMatrix * mat3(vertexTangent, cross(vertexTangent, vertexNormal), vertexNormal);

        #ifdef WORLD_LIGHT
            // Shadow light view matrix
            shdLightView = mat3(gbufferModelView) * vec3(shadowModelView[0].z, shadowModelView[1].z, shadowModelView[2].z);

            #ifdef SHD_ENABLE
                // Get shadow clip space pos
                shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos.xyz + shadowModelView[3].xyz) + shadowProjection[3].xyz;
                // Get distortion factor
                distortFactor = getDistortFactor(shdPos.xy);

                // Bias mutilplier, adjusts according to the current shadow distance and resolution
				float biasAdjustMult = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.25;

                // Apply shadow bias
                shdPos += (mat3(shadowProjection) * (mat3(shadowModelView) * (mat3(gbufferModelViewInverse) * TBN[2]))) * distortFactor * biasAdjustMult;
            #endif
        #endif

        // Lightmap fix for mods
        #ifdef WORLD_SKYLIGHT
            lmCoord = vec2(saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).x - 0.03125) * 1.06667), WORLD_SKYLIGHT);
        #else
            lmCoord = saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) * 1.06667);
        #endif

        #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        #ifdef ANIMATE
	        getVertexAnimations(feetPlayerPos.xyz, worldPos, texCoord, mc_midTexCoord.xy, mc_Entity.x, lmCoord.y);
        #endif

        #ifdef WORLD_CURVATURE
            feetPlayerPos.y -= dot(feetPlayerPos.xz, feetPlayerPos.xz) / WORLD_CURVATURE_SIZE;
        #endif
        
        // Clip pos
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * feetPlayerPos);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    #ifdef WORLD_LIGHT
        flat in vec3 shdLightView;

        #ifdef SHD_ENABLE
            in vec3 shdPos;

            in float distortFactor;
        #endif
    #endif

    flat in mat3 TBN;

    flat in int blockId;

    flat in vec3 vertexColor;

    in float vertexAO;

    in vec2 lmCoord;
    in vec2 texCoord;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;
        in vec2 vTexCoord;
    #endif

    in vec3 worldPos;

    in vec4 vertexPos;

    // Enable full vanilla AO
    const float ambientOcclusionLevel = 1.0;

    // Get albedo texture
    uniform sampler2D texture;

    // Get is eye in water
    uniform int isEyeInWater;

    // Get night vision
    uniform float nightVision;

    #if TIMELAPSE_MODE != 0
        uniform float animationFrameTime;

        float newFrameTimeCounter = animationFrameTime;
    #else
        float newFrameTimeCounter = frameTimeCounter;
    #endif

    // Texture coordinate derivatives
    vec2 dcdx = dFdx(texCoord);
    vec2 dcdy = dFdy(texCoord);

    #include "/lib/universalVars.glsl"

    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/surface/lava.glsl"

    #include "/lib/PBR/structPBR.glsl"

    #if PBR_MODE <= 1
        #include "/lib/PBR/defaultPBR.glsl"
    #else
        #include "/lib/PBR/labPBR.glsl"
    #endif

    #if defined ENVIRO_PBR && !defined FORCE_DISABLE_WEATHER
        #include "/lib/PBR/enviroPBR.glsl"
    #endif

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
	    // Declare materials
	    structPBR material;
        getPBR(material, blockId);

        if(blockId == 10001){
            #ifdef LAVA_NOISE
                vec2 lavaUv = (worldPos.yz * TBN[2].x + worldPos.xz * TBN[2].y + worldPos.xy * TBN[2].z) / LAVA_TILE_SIZE;
                float lavaNoise = max(getLavaNoise(lavaUv), (material.albedo.r + material.albedo.g + material.albedo.b) * 0.33333333);
                material.albedo.rgb = floor(material.albedo.rgb * saturate((lavaNoise - 0.33333333) * 3.0) * LAVA_BRIGHTNESS * 16.0) * 0.0625;
            #else
                material.albedo.rgb = material.albedo.rgb * LAVA_BRIGHTNESS;
            #endif
        }

        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRO_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != 10001) enviroPBR(material);
        #endif

        vec4 sceneCol = complexShadingGbuffers(material);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(material.normal, 1); // colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); // colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); // colortex3
    }
#endif