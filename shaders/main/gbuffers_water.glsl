#include "/lib/utility/util.glsl"
#include "/lib/structs.glsl"
#include "/lib/settings.glsl"

uniform int isEyeInWater;

uniform float nightVision;
uniform float rainStrength;

uniform ivec2 eyeBrightnessSmooth;

// Get frame time
uniform float frameTimeCounter;

// Get world time
uniform float day;
uniform float dawnDusk;
uniform float twilight;

INOUT float blockId;

INOUT vec2 lmCoord;
INOUT vec2 texCoord;

#if DEFAULT_MAT != 2 && defined AUTO_GEN_NORM
    INOUT vec2 minTexCoord;
    INOUT vec2 maxTexCoord;
#endif

INOUT vec4 glcolor;

INOUT mat3 TBN;

#ifdef VERTEX
    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    #include "/lib/vertex/vertexWave.glsl"

    uniform vec3 cameraPosition;

    uniform mat4 gbufferModelView;
    uniform mat4 gbufferModelViewInverse;

    attribute vec2 mcidTexCoord;

    attribute vec4 mc_Entity;
    attribute vec4 at_tangent;

    void main(){
        // Feet player pos
        vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
        blockId = mc_Entity.x;

        vec3 tangent = normalize(gl_NormalMatrix * at_tangent.xyz);
	    vec3 binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal) * sign(at_tangent.w));
	    vec3 normal = normalize(gl_NormalMatrix * gl_Normal);

	    TBN = mat3(gbufferModelViewInverse) * mat3(tangent, binormal, normal);

        #ifdef ANIMATE
            vec3 worldPos = vertexPos.xyz + cameraPosition;
	        getWave(vertexPos.xyz, worldPos, texCoord, mcidTexCoord, mc_Entity.x, lmCoord.y);
        #endif

        #if DEFAULT_MAT != 2 && defined AUTO_GEN_NORM
            vec2 texSize = abs(texCoord - mcidTexCoord.xy);
            minTexCoord = mcidTexCoord.xy - texSize;
            maxTexCoord = mcidTexCoord.xy + texSize;
            texCoord = step(mcidTexCoord.xy, texCoord);
        #endif
        
	    gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glcolor = gl_Color;
    }
#endif

#ifdef FRAGMENT
    // View matrix uniforms
    uniform mat4 gbufferModelViewInverse;

    // Projection matrix uniforms
    uniform mat4 gbufferProjectionInverse;

    // Shadow view matrix uniforms
    uniform mat4 shadowModelView;

    // Shadow projection matrix uniforms
    uniform mat4 shadowProjection;

    /* Position uniforms */
    uniform vec3 cameraPosition;

    /* Screen resolutions */
    uniform float viewWidth;
    uniform float viewHeight;

    uniform vec3 fogColor;

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
        posVector.worldPos = posVector.feetPlayerPos + cameraPosition;
        
		#ifdef SHD_ENABLE
			posVector.shdPos = mat3(shadowProjection) * (mat3(shadowModelView) * posVector.feetPlayerPos + shadowModelView[3].xyz) + shadowProjection[3].xyz;
		#endif

	    // Declare materials
	    matPBR material;
        int rBlockId = int(blockId + 0.5);
        getPBR(material, posVector, TBN, glcolor.rgb, texCoord, rBlockId);

        vec4 sceneCol = vec4(0);

        if(material.albedo.a > 0.00001){
            // If water
            if(rBlockId == 10034){
                float waterNoise = WATER_BRIGHTNESS;

                #if !(defined END || defined NETHER)
                    vec2 waterUv = posVector.worldPos.xz * (1.0 - TBN[2].y) + posVector.worldPos.xz * TBN[2].y;
                    
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
                float waterDepth = toView(posVector.screenPos.z) - toView(texture2D(depthtex1, posVector.screenPos.xy).x);

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
            
            // Apply vanilla AO
            material.ambient *= glcolor.a;
            material.light = lmCoord;

            #ifdef ENVIRO_MAT
                if(rBlockId != 10034) enviroPBR(material, posVector.worldPos, TBN[2]);
            #endif

            #if ANTI_ALIASING == 2
                sceneCol = complexShadingGbuffers(material, posVector, toRandPerFrame(getRand1(gl_FragCoord.xy * 0.03125), frameTimeCounter));
            #else
                sceneCol = complexShadingGbuffers(material, posVector, getRand1(gl_FragCoord.xy * 0.03125));
            #endif
        } else discard;

    /* DRAWBUFFERS:0123 */
        gl_FragData[0] = sceneCol; //gcolor
        gl_FragData[1] = vec4(material.normal * 0.5 + 0.5, 1); //colortex1
        gl_FragData[2] = vec4(material.albedo.rgb, 1); //colortex2
        gl_FragData[3] = vec4(material.metallic, material.smoothness, 0, 1); //colortex3
    }
#endif