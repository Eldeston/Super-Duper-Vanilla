// Get frame time
uniform float frameTimeCounter;

/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    #ifdef WORLD_LIGHT
        flat out mat3 shdVertexView;

        #ifdef SHD_ENABLE
            out vec3 shdPos;
        #endif
    #endif

    flat out mat3 TBN;

    flat out int blockId;

    flat out vec3 vertexColor;

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
            shdVertexView = mat3(shadowModelView) * mat3(gbufferModelViewInverse);

            #ifdef SHD_ENABLE
                // Get shadow clip space pos
                shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * feetPlayerPos.xyz + shadowModelView[3].xyz) + shadowProjection[3].xyz;
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
        flat in mat3 shdVertexView;

        #ifdef SHD_ENABLE
            in vec3 shdPos;
        #endif
    #endif

    flat in mat3 TBN;
    
    flat in int blockId;

    flat in vec3 vertexColor;

    in vec2 lmCoord;
    in vec2 texCoord;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
        flat in vec2 vTexCoordScale;
        flat in vec2 vTexCoordPos;
        in vec2 vTexCoord;
    #endif

    in vec3 worldPos;

    in vec4 vertexPos;

    // Get albedo texture
    uniform sampler2D texture;

    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    #ifdef WORLD_LIGHT
        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif

    #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
        uniform sampler2D depthtex1;
    #endif

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
    
    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/noiseFunctions.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/lighting/GGX.glsl"

    #include "/lib/surface/water.glsl"
    
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
        
        // If water
        if(blockId == 10000){
            float waterNoise = WATER_BRIGHTNESS;

            #ifdef WATER_NORM
                vec4 waterData = H2NWater(worldPos.xz);
                material.normal = TBN * waterData.xyz;

                #ifdef WATER_NOISE
                    waterNoise *= squared(0.128 + waterData.w);
                #endif
            #else
                float waterData = getCellNoise(worldPos.xz / WATER_TILE_SIZE);

                #ifdef WATER_NOISE
                    waterNoise *= squared(0.128 + waterData);
                #endif
            #endif

            #if defined WATER_STYLIZE_ABSORPTION || defined WATER_FOAM
                // Water color and foam 
                float waterDepth = toView(texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).x) - vertexPos.z;
            #endif

            #ifdef WATER_STYLIZE_ABSORPTION
                if(isEyeInWater == 0){
                        float depthBrightness = exp(waterDepth * 0.32);
                        material.albedo.rgb = min(vec3(1), material.albedo.rgb * mix(waterNoise, 2.0, depthBrightness));
                        material.albedo.a = fastSqrt(material.albedo.a) * (1.0 - depthBrightness);
                } else material.albedo.rgb *= waterNoise;
            #else
                material.albedo.rgb *= waterNoise;
            #endif

            #ifdef WATER_FOAM
                material.albedo = min(vec4(1), material.albedo + exp((0.1 + waterDepth) * 10.0));
            #endif
        }

        material.albedo.rgb = toLinear(material.albedo.rgb);

        #if defined ENVIRO_PBR && !defined FORCE_DISABLE_WEATHER
            if(blockId != 10000) enviroPBR(material);
        #endif

        vec4 sceneCol = complexShadingGbuffers(material);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(material.normal, 1); // colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); // colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); // colortex3
    }
#endif