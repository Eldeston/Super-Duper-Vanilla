// Get frame time
uniform float frameTimeCounter;

varying float blockId;

varying vec2 lmCoord;
varying vec2 texCoord;

#if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
    varying vec2 vTexCoordScale;
    varying vec2 vTexCoordPos;
    varying vec2 vTexCoord;
#endif

varying vec3 worldPos;
varying vec3 glcolor;

varying mat3 TBN;

// View matrix uniforms
uniform mat4 gbufferModelViewInverse;

#ifdef VERTEX
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

    #include "/lib/vertex/vertexAnimations.glsl"

    uniform mat4 gbufferModelView;

    #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION || defined ANIMATE
        attribute vec4 mc_midTexCoord;
    #endif

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
        // Get texture coordinates
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

        // Lightmap fix for mods
        #ifdef WORLD_SKYLIGHT
            lmCoord = vec2(saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).x - 0.03125) * 1.06667), WORLD_SKYLIGHT);
        #else
            lmCoord = saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) * 1.06667);
        #endif

        // Get block id
        blockId = mc_Entity.x;

        // Get TBN matrix
        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
        vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(gbufferModelViewInverse) * mat3(tangent, cross(tangent, normal), normal);

        #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
        worldPos = vertexPos.xyz + cameraPosition;

        #ifdef ANIMATE
	        getVertexAnimations(vertexPos.xyz, worldPos, texCoord, mc_midTexCoord.xy, mc_Entity.x, lmCoord.y);
        #endif

        #ifdef WORLD_CURVATURE
            vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
        #endif
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color.rgb;
    }
#endif

#ifdef FRAGMENT
    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    #ifdef WORLD_LIGHT
        // Shadow view matrix uniforms
        uniform mat4 shadowModelView;

        #ifdef SHD_ENABLE
            // Shadow projection matrix uniforms
            uniform mat4 shadowProjection;
        #endif
    #endif

    #if TIMELAPSE_MODE != 0
        uniform float animationFrameTime;

        float newFrameTimeCounter = animationFrameTime;
    #else
        float newFrameTimeCounter = frameTimeCounter;
    #endif

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    #if defined STYLIZED_WATER_ABSORPTION || defined WATER_FOAM
        uniform sampler2D depthtex1;
    #endif
    
    #include "/lib/universalVars.glsl"

    // Get is eye in water
    uniform int isEyeInWater;

    // Get night vision
    uniform float nightVision;
    
    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/noiseFunctions.glsl"
    #include "/lib/surface/water.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"
    
    #include "/lib/lighting/PBR.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Declare and get positions
        vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	    vec3 viewPos = toView(screenPos);
        vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;

	    // Declare materials
	    matPBR material;
        int rBlockId = int(blockId + 0.5);
        getPBR(material, eyePlayerPos, rBlockId);
        
        // If water
        if(rBlockId == 10000){
            float waterNoise = WATER_BRIGHTNESS;

            #ifdef WORLD_WATERNORM
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
            #endif

            #if defined STYLIZED_WATER_ABSORPTION || defined WATER_FOAM
                // Water color and foam 
                float waterDepth = toView(texture2D(depthtex1, screenPos.xy).x) - viewPos.z;
            #endif

            #ifdef STYLIZED_WATER_ABSORPTION
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

        material.albedo.rgb = pow(material.albedo.rgb, vec3(GAMMA));

        #if defined ENVIRO_MAT && !defined FORCE_DISABLE_WEATHER
            if(rBlockId != 10000) enviroPBR(material);
        #endif

        vec4 sceneCol = complexShadingGbuffers(material, eyePlayerPos);

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; // gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); //colortex3
    }
#endif