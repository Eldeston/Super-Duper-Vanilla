#ifdef FRAGMENT
    // For the use of texture2DGradARB in PBR.glsl
    #extension GL_ARB_shader_texture_lod : enable
#endif

#include "/lib/utility/util.glsl"
#include "/lib/settings.glsl"
#include "/lib/structs.glsl"

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

varying vec4 glcolor;

varying mat3 TBN;

// View matrix uniforms
uniform mat4 gbufferModelViewInverse;

/* Position uniforms */
uniform vec3 cameraPosition;

#ifdef VERTEX
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

    #include "/lib/vertex/vertexWave.glsl"

    uniform mat4 gbufferModelView;

    attribute vec4 mc_midTexCoord;
    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        // Lightmap fix for mods
        lmCoord = saturate(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) * 1.06667);
        blockId = mc_Entity.x;

        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	    vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * at_tangent.w);
	    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(gbufferModelViewInverse) * mat3(tangent, binormal, normal);

        #if defined AUTO_GEN_NORM || defined PARALLAX_OCCLUSION
            vec2 midCoord = (gl_TextureMatrix[0] * mc_midTexCoord).xy;
            vec2 texMinMidCoord = texCoord - midCoord;

            vTexCoordScale = abs(texMinMidCoord) * 2.0;
            vTexCoordPos = min(texCoord, midCoord - texMinMidCoord);
            vTexCoord = sign(texMinMidCoord) * 0.5 + 0.5;
        #endif

        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        #ifdef ANIMATE
            vec3 worldPos = vertexPos.xyz + cameraPosition;
	        getWave(vertexPos.xyz, worldPos, texCoord, mc_midTexCoord.xy, mc_Entity.x, lmCoord.y);
        #endif

        #ifdef WORLD_CURVATURE
            vertexPos.y -= lengthSquared(vertexPos.xz) / WORLD_CURVATURE_SIZE;
        #endif
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color;
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

    #include "/lib/universalVars.glsl"

    uniform sampler2D depthtex1;
    
    #include "/lib/lighting/shdDistort.glsl"
    #include "/lib/utility/convertViewSpace.glsl"
    #include "/lib/utility/texFunctions.glsl"
    #include "/lib/utility/noiseFunctions.glsl"
    #include "/lib/surface/water.glsl"

    #include "/lib/lighting/shdMapping.glsl"
    #include "/lib/lighting/GGX.glsl"
    
    #include "/lib/lighting/PBR.glsl"

    #include "/lib/lighting/complexShadingForward.glsl"

    void main(){
        // Declare and get positions
        positionVectors posVector;
        posVector.screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	    posVector.viewPos = toView(posVector.screenPos);
        posVector.eyePlayerPos = mat3(gbufferModelViewInverse) * posVector.viewPos;
        posVector.feetPlayerPos = posVector.eyePlayerPos + gbufferModelViewInverse[3].xyz;

	    // Declare materials
	    matPBR material;
        int rBlockId = int(blockId + 0.5);
        getPBR(material, posVector, rBlockId);
        
        vec3 worldPos = posVector.feetPlayerPos + cameraPosition;
        
        // If water
        if(rBlockId == 10001){
            float waterNoise = WATER_BRIGHTNESS;

            #if !(defined END || defined NETHER)
                vec2 waterUv = worldPos.xz * (1.0 - TBN[2].y) + worldPos.xz * TBN[2].y;

                #ifdef WATER_NORM
                    vec4 waterData = H2NWater(waterUv);
                    material.normal = normalize(TBN * waterData.xyz);

                    #ifdef WATER_NOISE
                        waterNoise *= squared(0.128 + waterData.w);
                    #endif
                #else
                    float waterData = getCellNoise(waterUv / WATER_TILE_SIZE);

                    #ifdef WATER_NOISE
                        waterNoise *= squared(0.128 + waterData);
                    #endif
                #endif
            #endif

            // Water color and foam 
            float waterDepth = posVector.viewPos.z - toView(texture2D(depthtex1, posVector.screenPos.xy).x);

            if(isEyeInWater != 1){
                #ifdef STYLIZED_WATER_ABSORPTION
                    float depthBrightness = exp(-waterDepth * 0.32);
                    material.albedo.rgb = mix(material.albedo.rgb * waterNoise, saturate(toneSaturation(material.albedo.rgb, 2.0) * 2.0), depthBrightness);
                    material.albedo.a = sqrt(material.albedo.a) * (1.0 - depthBrightness);
                #endif
            } else material.albedo.rgb *= waterNoise;

            #ifdef WATER_FOAM
                float foam = min(1.0, exp(-(waterDepth - 0.128) * 10.0));
                material.albedo = material.albedo * (1.0 - foam) + foam;
            #endif
        }

        material.albedo.rgb = pow(material.albedo.rgb, vec3(GAMMA));

        material.light = lmCoord;

        #ifdef ENVIRO_MAT
            if(rBlockId != 10034) enviroPBR(material, worldPos);
        #endif

        #if ANTI_ALIASING == 2
            vec4 sceneCol = complexShadingGbuffers(material, posVector, toRandPerFrame(getRand1(gl_FragCoord.xy * 0.03125), frameTimeCounter));
        #else
            vec4 sceneCol = complexShadingGbuffers(material, posVector, getRand1(gl_FragCoord.xy * 0.03125));
        #endif

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); //colortex3
    }
#endif